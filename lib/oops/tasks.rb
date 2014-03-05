require 'oops/opsworks_deploy'
require 'aws'
namespace :oops do
  task :build, [:filename] => 'assets:precompile' do |t, args|
    args.with_defaults filename: default_filename

    file_path = args.filename

    sh %{mkdir -p build}
    sh %{git archive --format zip --output build/#{file_path} HEAD}

    sh %{zip -r -g build/#{file_path} public/}
    sh %{zip -r -g build/#{file_path} .env*}
    sh %{zip build/#{file_path} -d .gitignore}

    sh %{rm -rf public/assets}

    puts "Packaged Application: #{file_path}"
  end

  task :upload, :filename do |t, args|
    args.with_defaults filename: default_filename

    file_path = args.filename
    s3 = s3_object(file_path)

    puts "Starting upload..."
    s3.write(file: "build/#{file_path}")
    puts "Uploaded Application: #{s3.url_for(:read)}"
  end

  task :deploy, :app_name, :stack_name, :filename do |t, args|
    raise "app_name variable is required" unless (app_name = args.app_name)
    raise "stack_name variable is required" unless (stack_name = args.stack_name)
    args.with_defaults filename: default_filename
    file_path = args.filename
    file_url = s3_url file_path

    ENV['AWS_REGION'] = 'us-east-1'

    if !s3_object(file_path).exists?
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
  def s3_object file_path
    AWS::S3.new.buckets[bucket_name].objects["#{package_folder}/#{file_path}"]
  end

  def s3_url file_path
    s3_object(file_path).public_url.to_s
  end

  def build_hash
    @build_hash ||= `git rev-parse HEAD`.strip
  end

  def default_filename
    ENV['PACKAGE_FILENAME'] || "git-#{build_hash}.zip"
  end

  def package_folder
    raise "PACKAGE_FOLDER environment variable required" unless ENV['PACKAGE_FOLDER']
    ENV['PACKAGE_FOLDER']
  end

  def bucket_name
    raise "DEPLOY_BUCKET environment variable required" unless ENV['DEPLOY_BUCKET']
    ENV['DEPLOY_BUCKET']
  end

end
