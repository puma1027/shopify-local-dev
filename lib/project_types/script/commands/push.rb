# frozen_string_literal: true

module Script
  class Command
    class Push < ShopifyCli::SubCommand
      options do |parser, flags|
        parser.on("--force") { |t| flags[:force] = t }
      end

      def call(_args, _name)
        ShopifyCli::Tasks::EnsureEnv.call(@ctx, required: [:api_key, :secret, :shop])

        api_key = Layers::Infrastructure::ScriptProjectRepository.new(ctx: @ctx).get.api_key
        return @ctx.puts(self.class.help) unless api_key

        Layers::Application::PushScript.call(ctx: @ctx, force: options.flags.key?(:force))
        @ctx.puts(@ctx.message("script.push.script_pushed", api_key: api_key))
      rescue StandardError => e
        msg = @ctx.message("script.push.error.operation_failed", api_key: api_key)
        UI::ErrorHandler.pretty_print_and_raise(e, failed_op: msg)
      end

      def self.help
        ShopifyCli::Context.message("script.push.help", ShopifyCli::TOOL_NAME)
      end
    end
  end
end
