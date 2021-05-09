# frozen_string_literal: true
require "project_types/node/test_helper"

module ShopifyCli
  module Commands
    module PopulateTests
      class ProductTest < MiniTest::Test
        include TestHelpers::Schema

        def test_populate_calls_api_with_mutation
          ShopifyCli::Helpers::Haikunator.expects(:title).returns("fake product")
          ShopifyCli::Helpers::Haikunator.expects(:title).returns("fake producttwo")
          ShopifyCli::DB.expects(:exists?).with(:shop).returns(true)
          ShopifyCli::DB.expects(:get).with(:shop).returns("my-test-shop.myshopify.com")
          ShopifyCli::AdminAPI::PopulateResourceCommand.any_instance.stubs(:price).returns("1.00")
          return_data = JSON.parse(File.read(File.join(FIXTURE_DIR, "populate/product_data.json")))
          ShopifyCli::AdminAPI.expects(:query)
            .with(@context, "create_product", shop: "my-test-shop.myshopify.com", api_version: "2021-01", input: {
              'title': "fake product",
              variants: [{ price: "1.00" }],
            })
            .returns(return_data)
          ShopifyCli::AdminAPI.expects(:query)
            .with(@context, "create_product", shop: "my-test-shop.myshopify.com", api_version: "2021-01", input: {
              'title': "fake producttwo",
              variants: [{ price: "1.00" }],
            })
            .returns(return_data)
          ShopifyCli::API.expects(:gid_to_id).returns(12345678).twice
          @context.expects(:done).with(
            "fake product added to {{green:my-test-shop.myshopify.com}} at" \
            " {{underline:https://my-test-shop.myshopify.com/admin/products/12345678}}"
          ).twice
          run_cmd("populate products -c 2")
        end

        def test_populate_if_no_shop
          ShopifyCli::DB.expects(:exists?).with(:shop).returns(false)
          ShopifyCli::AdminAPI.expects(:query).never
          exception = assert_raises ShopifyCli::Abort do
            run_cmd("populate products")
          end
          assert_equal(
            "{{x}} " + @context.message("core.populate.error.no_shop", ShopifyCli::TOOL_NAME),
            exception.message
          )
        end
      end
    end
  end
end
