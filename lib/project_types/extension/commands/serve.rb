# frozen_string_literal: true

module Extension
  module Commands
    class Serve < ExtensionCommand
      DEFAULT_PORT = 39351

      options do |parser, flags|
        parser.on("-t", "--[no-]tunnel", "Establish an ngrok tunnel") { |tunnel| flags[:tunnel] = tunnel }
      end

      class RuntimeConfiguration
        include SmartProperties

        property! :tunnel_url, accepts: String, default: ""
        property! :tunnel_requested, accepts: [true, false], reader: :tunnel_requested?, default: true
        property! :port, accepts: (1...(2**16)), default: DEFAULT_PORT
      end

      def call(_args, _command_name)
        config = RuntimeConfiguration.new(
          tunnel_requested: tunnel_requested?
        )

        ShopifyCli::Result
          .success(config)
          .then(&method(:find_available_port))
          .then(&method(:start_tunnel_if_required))
          .then(&method(:serve))
          .unwrap { |error| raise error }
      end

      def self.help
        <<~HELP
          Serve your extension in a local simulator for development.
            Usage: {{command:#{ShopifyCli::TOOL_NAME} serve}}
            Options:
            {{command:--tunnel=TUNNEL}} Establish an ngrok tunnel (default: false)
        HELP
      end

      private

      def tunnel_requested?
        tunnel = options.flags[:tunnel]
        tunnel.nil? || !!tunnel
      end

      def find_available_port(runtime_configuration)
        chosen_port = Tasks::ChooseNextAvailablePort
          .call(from: runtime_configuration.port)
          .unwrap { |_error| @ctx.abort(@ctx.message("serve.no_available_ports_found")) }

        runtime_configuration.tap { |c| c.port = chosen_port }
      end

      def start_tunnel_if_required(runtime_configuration)
        if runtime_configuration.tunnel_requested?
          tunnel_url = ShopifyCli::Tunnel.start(@ctx, port: runtime_configuration.port)
          runtime_configuration.tap { |c| c.tunnel_url = tunnel_url }
        end
        runtime_configuration
      end

      def serve(runtime_configuration)
        specification_handler.serve(
          context: @ctx,
          tunnel_url: runtime_configuration.tunnel_url,
          port: runtime_configuration.port
        )
        runtime_configuration
      end
    end
  end
end
