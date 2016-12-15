require 'oops/opsworks_deploy'
require 'aws-sdk'
require 'rake'

module Oops
  class Tasks
    attr_accessor :prerequisites, :additional_paths, :includes, :excludes, :format

    def self.default_args
      {
        prerequisites: ['assets:clean', 'assets:precompile'],
        additional_paths: [],
        includes: ['public/assets', 'public/packs'],
        excludes: ['.gitignore'],
        format: 'zip'
      }
    end

    def initialize(&block)
      self.class.default_args.each do |key, value|
        public_send("#{key}=", value)
      end
      yield(self)
      create_task!
    end

    def add_file file_path, path
      if format == 'zip'
        sh *%W{zip -r -g build/#{file_path} #{path}}
      elsif format == 'tar'
        sh *%W{tar -r -f build/#{file_path} #{path}}
      end
    end

    def remove_file file_path, path
      if format == 'zip'
        sh *%W{zip build/#{file_path} -d #{path}}
      elsif format == 'tar'
        sh *%W{tar --delete -f build/#{file_path} #{path}}
      end
    end

    private
    include Rake::DSL
    def create_task!
      # Remove any existing definition
      Rake::Task["oops:build"].clear if Rake::Task.task_defined?("oops:build")

      namespace :oops do
        task :build, [:filename] => prerequisites do |t, args|
          args.with_defaults filename: oops_default_filename

          file_path = args.filename

          sh %{mkdir -p build}
          sh %{git archive --format #{format} --output build/#{file_path} HEAD}

          (includes + additional_paths).each do |path|
            add_file file_path, path
          end

          excludes.each do |path|
            remove_file file_path, path
          end

          puts "Packaged Application: #{file_path}"
        end
      end
    end
  end
end

# Initialize build task with defaults
Oops::Tasks.new do
end

namespace :oops do
  task :upload, :filename do |t, args|
    args.with_defaults filename: oops_default_filename

    file_path = args.filename
    s3 = oops_s3_object(file_path)

    puts "Starting upload..."
    s3.upload_file("build/#{file_path}")
    puts "Uploaded Application: #{s3.public_url}"
  end

  task :deploy, :app_name, :stack_name, :filename do |t, args|
    raise "app_name variable is required" unless (app_name = args.app_name)
    raise "stack_name variable is required" unless (stack_name = args.stack_name)
    args.with_defaults filename: oops_default_filename
    file_path = args.filename
    file_url = oops_s3_url file_path

    ENV['AWS_REGION'] ||= 'us-east-1'

    if !oops_s3_object(file_path).exists?
      raise "Artifact \"#{file_url}\" doesn't seem to exist\nMake sure you've run `RAILS_ENV=deploy rake opsworks:build opsworks:upload` before deploying"
    end

    ops = Oops::OpsworksDeploy.new args.app_name, args.stack_name
    deployment = ops.deploy(file_url)

    STDOUT.sync = true
    STDOUT.print "Deploying"
    loop do
      STDOUT.print "."
      break if deployment.finished?
      sleep 5
    end

    STDOUT.puts "\nStatus: #{deployment.status}"
    raise "Deploy failed. Check the OpsWorks console." if deployment.failed?
  end

  private
  def oops_s3_object file_path
    s3 = Aws::S3::Resource.new
    s3.bucket(oops_bucket_name).object("#{oops_package_folder}/#{file_path}")
  end

  def oops_s3_url file_path
    oops_s3_object(file_path).public_url.to_s
  end

  def oops_build_hash
    @oops_build_hash ||= `git rev-parse HEAD`.strip
  end

  def oops_default_filename
    ENV['PACKAGE_FILENAME'] || "git-#{oops_build_hash}.zip"
  end

  def oops_package_folder
    raise "PACKAGE_FOLDER environment variable required" unless ENV['PACKAGE_FOLDER']
    ENV['PACKAGE_FOLDER']
  end

  def oops_bucket_name
    raise "DEPLOY_BUCKET environment variable required" unless ENV['DEPLOY_BUCKET']
    ENV['DEPLOY_BUCKET']
  end

end
