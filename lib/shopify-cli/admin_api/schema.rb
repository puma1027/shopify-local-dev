require "shopify_cli"

module ShopifyCli
  class AdminAPI
    class Schema < Hash
      class << self
        def get(ctx)
          unless ShopifyCli::DB.exists?(:shopify_admin_schema)
            shop = AdminAPI.get_shop(ctx)
            schema = AdminAPI.query(ctx, "admin_introspection", shop: shop)
            ShopifyCli::DB.set(shopify_admin_schema: JSON.dump(schema))
          end
          # This is ruby magic for making a new hash with another hash.
          # It wraps the JSON in our Schema Class to have the helper methods
          # available
          self[JSON.parse(ShopifyCli::DB.get(:shopify_admin_schema))]
        end
      end

      def type(name)
        data = self["data"]
        schema = data["__schema"]
        schema["types"].find do |object|
          object["name"] == name.to_s
        end
      end

      def get_names_from_type(name)
        type(name)["enumValues"].map do |object|
          object["name"]
        end
      end
    end
  end
end
