require 'shopify_cli'

module ShopifyCli
  module Commands
    class Create < ShopifyCli::Command
      prerequisite_task :tunnel

      def call(args, _name)
        @name = args.shift
        return puts CLI::UI.fmt(self.class.help) unless @name
        api_key = CLI::UI.ask('What is your Shopify API Key')
        api_secret = CLI::UI.ask('What is your Shopify API Secret')
        @ctx.app_metadata = {
          api_key: api_key,
          secret: api_secret,
        }
        app_type = CLI::UI::Prompt.ask('What type of app would you like to create?') do |handler|
          AppTypeRegistry.each do |identifier, type|
            handler.option(type.description) { identifier }
          end
        end

        return puts "not yet implemented" unless app_type

        AppTypeRegistry.build(app_type, @name, @ctx)

        ShopifyCli::Project.write(@ctx, app_type)
      end

      def self.help
        <<~HELP
          Bootstrap an app.
          Usage: {{command:#{ShopifyCli::TOOL_NAME} create <appname>}}
        HELP
      end
    end
  end
end
