# frozen_string_literal: true

module Script
  module Commands
    class Push < ShopifyCli::Command
      options do |parser, flags|
        parser.on('--force') { |t| flags[:force] = t }
      end

      def call(_args, _name)
        ShopifyCli::Tasks::EnsureEnv.call(@ctx, required: [:api_key, :secret, :shop])
        project = ScriptProject.current
        api_key = project.env[:api_key]
        return @ctx.puts(self.class.help) unless api_key

        Layers::Application::PushScript.call(
          ctx: @ctx,
          language: project.language,
          extension_point_type: project.extension_point_type,
          script_name: project.script_name,
          api_key: api_key,
          force: options.flags.key?(:force)
        )
        @ctx.puts(@ctx.message('script.push.script_pushed', api_key: api_key))
      rescue StandardError => e
        UI::ErrorHandler.pretty_print_and_raise(e, failed_op: @ctx.message('script.push.error.operation_failed'))
      end

      def self.help
        ShopifyCli::Context.message('script.push.help', ShopifyCli::TOOL_NAME)
      end
    end
  end
end
