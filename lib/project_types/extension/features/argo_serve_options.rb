module Extension
  module Features
    class ArgoServeOptions
      include SmartProperties

      property! :cli_compatibility, accepts: Features::ArgoCliCompatibility
      property! :context, accepts: ShopifyCli::Context
      property  :port, accepts: Integer, default: 39351
      property  :public_url, accepts: String, default: ""
      property! :required_fields, accepts: Array, default: -> { [] }
      property! :renderer_package, accepts: Features::ArgoRendererPackage

      YARN_SERVE_COMMAND = %w(server)
      NPM_SERVE_COMMAND = %w(run-script server)

      def yarn_serve_command
        YARN_SERVE_COMMAND + options
      end

      def npm_serve_command
        NPM_SERVE_COMMAND  + ["--"] + options
      end

      private

      def options
        project = ExtensionProject.current

        @serve_options ||= [].tap do |options|
          options << "--port=#{port}" if cli_compatibility.accepts_port?
          options << "--shop=#{project.env.shop}" if required_fields.include?(:shop)
          options << "--apiKey=#{project.env.api_key}" if required_fields.include?(:api_key)
          options << "--argoVersion=#{renderer_package.version}" if cli_compatibility.accepts_argo_version?
          options << "--uuid=#{project.registration_uuid}" if cli_compatibility.accepts_uuid?
          options << "--publicUrl=#{public_url}" if cli_compatibility.accepts_tunnel_url?
        end
      end
    end
  end
end
