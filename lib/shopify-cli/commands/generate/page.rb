require 'shopify_cli'

module ShopifyCli
  module Commands
    class Generate
      class Page < ShopifyCli::Task
        def call(ctx, args)
          if args.empty?
            ctx.puts(self.class.help)
            return
          end
          project = ShopifyCli::Project.current
          name = args.first
          types = project.app_type.page_types
          # temporary check until we build for rails
          if project.app_type == ShopifyCli::AppTypes::Rails
            raise(ShopifyCli::Abort, 'This feature is not yet available for Rails apps')
          end
          selected_type = CLI::UI::Prompt.ask('Which template would you like to use?') do |handler|
            types.each do |key, value|
              handler.option(key) { value }
            end
          end
          spin_group = CLI::UI::SpinGroup.new
          spin_group.add("Generating #{types.key(selected_type)} page...") do |spinner|
            ShopifyCli::Commands::Generate.run_generate(
              "#{project.app_type.generate[selected_type]} #{name}", name, ctx
            )
            spinner.update_title("{{green: #{name}}} generated in /pages/#{name}")
          end
          spin_group.wait
        end

        def self.help
          <<~HELP
            Generate a new page in your app with the specified name. New files are generated inside the project’s “/pages” directory.
              Usage: {{command:#{ShopifyCli::TOOL_NAME} generate page <pagename>}}
          HELP
        end
      end
    end
  end
end
