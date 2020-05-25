# frozen_string_literal: true

module Extension
  module Commands
    class Create < ShopifyCli::SubCommand
      options do |parser, flags|
        parser.on('--name=NAME') { |name| flags[:name] = name }
        parser.on('--type=TYPE') { |type| flags[:type] = type.upcase  }
      end

      def call(args, _)
        with_create_form(args) do |form|
          form.type.create(form.directory_name, @ctx)

          ExtensionProject.write_cli_file(context: @ctx, type: form.type.identifier)
          ExtensionProject.write_env_file(context: @ctx, title: form.name)

          @ctx.puts(Content::Create::READY_TO_START % [form.name, form.directory_name])
          @ctx.puts(Content::Create::LEARN_MORE % form.type.name)
        end
      end

      def self.help
        <<~HELP
          Create a new app extension.
            Usage: {{command:#{ShopifyCli::TOOL_NAME} create extension <name>}}
            Options:
              {{command:--type=TYPE}} The type of extension you would like to create.
              {{command:--name=NAME}} The name of your extension (50 characters).”
        HELP
      end

      private

      def with_create_form(args)
        form = Forms::Create.ask(@ctx, args, options.flags)
        return @ctx.puts(self.class.help) if form.nil?

        yield form
      end
    end
  end
end
