# frozen_string_literal: true
require "shopify-cli/theme/theme"
require "shopify-cli/theme/development_theme"

module Theme
  class Command
    class Delete < ShopifyCli::SubCommand
      options do |parser, flags|
        parser.on("-d", "--development") { flags[:development] = true }
      end

      def call(args, _name)
        themes = if options.flags[:development]
          [ShopifyCli::Theme::DevelopmentTheme.new(@ctx)]
        elsif args.any?
          args.map { |id| ShopifyCli::Theme::Theme.new(@ctx, id: id) }
        else
          [Forms::Select.ask(
            @ctx,
            [],
            title: @ctx.message("theme.delete.select"),
            exclude_roles: ["live"],
          ).theme]
        end

        deleted = 0
        themes.each do |theme|
          if theme.live?
            @ctx.puts(@ctx.message("theme.delete.live", theme.id))
            next
          end
          theme.delete
          deleted += 1
        rescue ShopifyCli::API::APIRequestNotFoundError
          @ctx.puts(@ctx.message("theme.delete.not_found", theme.id))
        end

        @ctx.done(@ctx.message("theme.delete.done", deleted))
      end

      def self.help
        ShopifyCli::Context.message("theme.delete.help", ShopifyCli::TOOL_NAME, ShopifyCli::TOOL_NAME)
      end
    end
  end
end
