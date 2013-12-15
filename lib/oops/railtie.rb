module Oops
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'oops/tasks.rb'
    end
  end
end
