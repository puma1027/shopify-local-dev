# frozen_string_literal: true
require "shopify_cli"

module Node
  class Command
    class Generate < ShopifyCli::SubCommand
      prerequisite_task ensure_project_type: :node

      def call(*)
        @ctx.puts(self.class.help)
      end

      def self.help
        ShopifyCli::Context.message("node.generate.help")
      end

      def self.extended_help
        help
      end
    end
  end
end
