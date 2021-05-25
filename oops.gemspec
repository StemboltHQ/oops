# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oops/version'

Gem::Specification.new do |spec|
  spec.name          = "oops"
  spec.version       = Oops::VERSION
  spec.authors       = ["Clarke Brunsdon"]
  spec.email         = ["clarke@freerunningtechnologies.com"]
  spec.description   = %q{Oops Opsworks Postal Service: Made to ship code}
  spec.summary       = %q{Provides rake tasks to create and deploy build artifacts to opsworks}
  spec.homepage      = "http://github.com/freerunningtech/oops"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk", "~> 3.0"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
