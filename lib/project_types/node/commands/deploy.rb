# frozen_string_literal: true
require "shopify_cli"

module Node
  class Command
    class Deploy < ShopifyCLI::SubCommand
      prerequisite_task ensure_project_type: :node

      autoload :Heroku, Project.project_filepath("commands/deploy/heroku")

      HEROKU = "heroku"

      def call(args, _name)
        subcommand = args.shift
        case subcommand
        when HEROKU
          Node::Command::Deploy::Heroku.start(@ctx)
        else
          @ctx.puts(self.class.help)
        end
      end

      def self.help
        ShopifyCLI::Context.message("node.deploy.help", ShopifyCLI::TOOL_NAME)
      end

      def self.extended_help
        ShopifyCLI::Context.message("node.deploy.extended_help", ShopifyCLI::TOOL_NAME)
      end
    end
  end
end
