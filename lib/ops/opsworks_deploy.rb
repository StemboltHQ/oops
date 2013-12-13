module Ops class OpsworksDeploy
    attr_accessor :stack_name, :app_name

    def initialize(app_name, stack_name)
      @client = AWS::OpsWorks::Client.new
      self.stack_name = stack_name
      self.app_name = app_name
    end

    def deploy(file_url)
      @client.update_app(app_id: app_id, app_source: { url: file_url })
      instance_ids = @client.describe_instances(stack_id: stack_id).instances.map(&:instance_id).to_a
      deployment = @client.create_deployment(stack_id: stack_id, app_id: app_id, command: { name: 'deploy', args: { "migrate"=>["true"] } }, instance_ids: instance_ids )
      Deployment.new(@client, deployment)
    end

    class Deployment

      def finished?
        status != 'running'
      end

      def status
        @client.describe_deployments(deployment_ids: [deployment.deployment_id]).deployments[0].status
      end

      def failed?
        status == 'failed'
      end

      protected
      def initialize(client, deployment)
        @client = client
        @deployment = deployment
      end

    end

    private

    def stack_id
      @stack_id ||= @client.describe_stacks[:stacks].detect { |x| x[:name] == stack_name }[:stack_id]
    end

    def app_id
      @app_id ||= @client.describe_apps(stack_id: stack_id)[:apps].detect { |x| x[:name] == app_name }[:app_id]
    end

  end

end
