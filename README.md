# Oops: The Opsworks Postal Service

Oops handles the creation and deployment of rails applications to Amazon's Opsworks (http://aws.amazon.com/opsworks/).

It provides rake tasks to bundle your application, along with all of its assets, into a .zip that is uploaded to s3. That artifact is then used to deploy your application. This saves production boxes from running asset precompiles and avoids git checkouts on your running servers.

## Installation

Add this line to your application's Gemfile:

    gem 'oops'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install oops

## Usage

Variables are passed into ops using both environment variables and rake arguements.

To create a build:
    AWS_ACCESS_KEY_ID=MY_ACCESS_KEY AWS_SECRET_ACCESS_KEY=MY_SECRET_KEY DEPLOY_BUCKET=oops-deploy PACKAGE_FOLDER=opsbuilds bundle exec rake oops:build

To upload a build:
    AWS_ACCESS_KEY_ID=MY_ACCESS_KEY AWS_SECRET_ACCESS_KEY=MY_SECRET_KEY DEPLOY_BUCKET=oops-deploy PACKAGE_FOLDER=opsbuilds bundle exec rake oops:upload

To deploy a build:
    AWS_ACCESS_KEY_ID=MY_ACCESS_KEY AWS_SECRET_ACCESS_KEY=MY_SECRET_KEY DEPLOY_BUCKET=oops-deploy PACKAGE_FOLDER=opsbuilds bundle exec rake oops:deploy[my_application_name,my_stack_name]

By default, these tasks will all deploy what is in your current HEAD, but can also be passed an optional ref to deploy a specific revision.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
