require 'test_helper'

module ShopifyCli
  class AdminAPI
    class SchemaTest < MiniTest::Test
      include TestHelpers::Project

      def setup
        super
        json_data = File.read(File.join(ShopifyCli::ROOT, "test/fixtures/shopify_schema.json"))
        @test_obj = AdminAPI::Schema[JSON.parse(json_data)]
        @enum = {
          "kind" => "ENUM",
          "name" => "WebhookSubscriptionTopic",
          "enumValues" => [{ "name" => "APP_UNINSTALLED" }],
        }
      end

      def test_gets_schema
        ShopifyCli::DB.expects(:exists?).returns(false)
        ShopifyCli::DB.expects(:set).with(shopify_admin_schema: "{\"foo\":\"baz\"}")
        ShopifyCli::DB.expects(:get).with(:shopify_admin_schema).returns("{\"foo\":\"baz\"}")
        ShopifyCli::AdminAPI.expects(:query)
          .with(@context, 'admin_introspection', shop: 'my-test-shop.myshopify.com')
          .returns(foo: "baz")
        assert_equal({ "foo" => "baz" }, AdminAPI::Schema.get(@context))
      end

      def test_gets_schema_if_already_downloaded
        ShopifyCli::DB.expects(:exists?).returns(true)
        ShopifyCli::DB.expects(:get).with(:shopify_admin_schema).returns("{\"foo\":\"baz\"}")
        assert_equal({ "foo" => "baz" }, AdminAPI::Schema.get(@context))
      end

      def test_access
        assert_equal(@test_obj.type('WebhookSubscriptionTopic'), @enum)
      end

      def test_get_names_from_enum
        assert_equal(["APP_UNINSTALLED"], @test_obj.get_names_from_type('WebhookSubscriptionTopic'))
      end
    end
  end
end
