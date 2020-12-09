require 'uri'

module Node
  module Forms
    class Create < ShopifyCli::Form
      attr_accessor :name
      flag_arguments :title, :organization_id, :shop_domain, :type

      def ask
        self.title ||= CLI::UI::Prompt.ask(ctx.message('node.forms.create.app_name'))
        self.type = ask_type
        self.name = self.title.downcase.split(' ').join('_')
        res = ShopifyCli::Tasks::SelectOrgAndShop.call(ctx, organization_id: organization_id, shop_domain: shop_domain)
        self.organization_id = res[:organization_id]
        self.shop_domain = res[:shop_domain]
      end

      private

      def ask_type
        if type.nil?
          return(
            CLI::UI::Prompt.ask(ctx.message('node.forms.create.app_type.select')) do |handler|
              handler.option(ctx.message('node.forms.create.app_type.select_public')) { 'public' }
              handler.option(ctx.message('node.forms.create.app_type.select_custom')) { 'custom' }
            end
          )
        end

        unless ShopifyCli::Tasks::CreateApiClient::VALID_APP_TYPES.include?(type)
          ctx.abort(ctx.message('node.forms.create.error.invalid_app_type', type))
        end
        ctx.puts(ctx.message('node.forms.create.app_type.selected', type))
        type
      end
    end
  end
end
