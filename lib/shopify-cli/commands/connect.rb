require 'shopify_cli'

module ShopifyCli
  module Commands
    class Connect < ShopifyCli::Command
      def call(*)
        project_type = ask_project_type unless Project.has_current?

        if Project.has_current? && Project.current && Project.current.env
          @ctx.puts @ctx.message('core.connect.already_connected_warning')
          prod_warning = @ctx.message('core.connect.production_warning')
          @ctx.puts prod_warning if [:rails, :node].include?(Project.current_project_type)
        end

        env_data = begin
          Resources::EnvFile.parse_external_env
                   rescue Errno::ENOENT
                     {}
        end

        org = fetch_org
        id = org['id']
        app = get_app(id, org['apps'])
        shop = get_shop(org['stores'], id)

        write_env(app, shop, env_data[:scopes], env_data[:extra])
        write_cli_yml(project_type, id) unless Project.has_current?

        @ctx.puts(@ctx.message('core.connect.connected', app['title']))
      end

      def ask_project_type
        CLI::UI::Prompt.ask(@ctx.message('core.connect.project_type_select')) do |handler|
          ShopifyCli::Commands::Create.all_visible_type.each do |type|
            handler.option(type.project_name) { type.project_type }
          end
        end
      end

      def fetch_org
        orgs = PartnersAPI::Organizations.fetch_with_app(@ctx)
        org_id = if orgs.count == 1
          orgs.first["id"]
        else
          CLI::UI::Prompt.ask(@ctx.message('core.connect.organization_select')) do |handler|
            orgs.each do |org|
              handler.option(
                @ctx.message('core.partners_api.org_name_and_id', org['businessName'], org['id'])
              ) { org["id"] }
            end
          end
        end
        org = orgs.find { |o| o["id"] == org_id }
        org
      end

      def get_app(org_id, apps)
        if apps.count == 1
          apps.first
        elsif apps.count == 0
          @ctx.puts(@ctx.message('core.connect.no_apps'))
          title = CLI::UI::Prompt.ask(@ctx.message('core.connect.app_name'))
          type = CLI::UI::Prompt.ask(@ctx.message('core.connect.app_type.select')) do |handler|
            handler.option(@ctx.message('core.connect.app_type.select_public')) { 'public' }
            handler.option(@ctx.message('core.connect.app_type.select_custom')) { 'custom' }
          end
          ShopifyCli::Tasks::CreateApiClient.call(@ctx, org_id: org_id, title: title, type: type)
        else
          CLI::UI::Prompt.ask(@ctx.message('core.connect.app_select')) do |handler|
            apps.each { |app| handler.option(app["title"]) { app } }
          end
        end
      end

      def get_shop(shops, id)
        if shops.count == 1
          shop = shops.first["shopDomain"]
        elsif shops.count == 0
          @ctx.puts(@ctx.message('core.connect.no_development_stores', id))
        else
          shop = CLI::UI::Prompt.ask(@ctx.message('core.connect.development_store_select')) do |handler|
            shops.each { |s| handler.option(s["shopName"]) { s["shopDomain"] } }
          end
        end
        shop
      end

      def write_env(app, shop, scopes, extra)
        scopes = 'write_products,write_customers,write_draft_orders' if scopes.nil?
        extra = {} if extra.nil?

        Resources::EnvFile.new(
          api_key: app["apiKey"],
          secret: app["apiSecretKeys"].first["secret"],
          shop: shop,
          scopes: scopes,
          extra: extra,
        ).write(@ctx)
      end

      def write_cli_yml(project_type, org_id)
        ShopifyCli::Project.write(
          @ctx,
          project_type: project_type,
          organization_id: org_id,
        )
        @ctx.done(@ctx.message('core.connect.cli_yml_saved'))
      end

      def self.help
        ShopifyCli::Context.message('core.connect.help', ShopifyCli::TOOL_NAME)
      end
    end
  end
end
