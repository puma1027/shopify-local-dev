module ShopifyCli
  class PartnersAPI
    class Organizations
      class << self
        def fetch_all(ctx)
          resp = PartnersAPI.query(ctx, 'all_organizations')
          resp['data']['organizations']['nodes'].map do |org|
            org['stores'] = org['stores']['nodes']
            org
          end
        end

        def fetch(ctx, id:)
          resp = PartnersAPI.query(ctx, 'find_organization', id: id)
          org = resp['data']['organizations']['nodes'].first
          return nil if org.nil?
          org['stores'] = org['stores']['nodes']
          org
        end

        def fetch_with_app(ctx)
          resp = PartnersAPI.query(ctx, 'all_orgs_with_apps')
          resp['data']['organizations']['nodes'].map do |org|
            org['stores'] = org['stores']['nodes']
            org['apps'] = org['apps']['nodes']
            org
          end
        end
      end
    end
  end
end
