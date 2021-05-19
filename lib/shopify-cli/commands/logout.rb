require "shopify_cli"
require "shopify-cli/theme/development_theme"

module ShopifyCli
  module Commands
    class Logout < ShopifyCli::Command
      def call(*)
        try_delete_development_theme
        ShopifyCli::IdentityAuth.delete_tokens_and_keys
        ShopifyCli::DB.del(:shop) if ShopifyCli::DB.exists?(:shop)
        ShopifyCli::Shopifolk.reset
        @ctx.puts(@ctx.message("core.logout.success"))
      end

      def self.help
        ShopifyCli::Context.message("core.logout.help", ShopifyCli::TOOL_NAME)
      end

      private

      def try_delete_development_theme
        ShopifyCli::Theme::DevelopmentTheme.delete(@ctx)
      rescue ShopifyCli::API::APIRequestError
        # Ignore since we can't delete it
      end
    end
  end
end
