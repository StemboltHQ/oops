module Ops
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'ops/tasks.rb'
    end
  end
end
