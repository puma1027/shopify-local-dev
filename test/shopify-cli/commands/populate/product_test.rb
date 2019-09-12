require 'test_helper'

module ShopifyCli
  module Commands
    class Populate
      class ProductTest < MiniTest::Test
        include TestHelpers::Project
        include TestHelpers::Schema

        def setup
          super
          Helpers::AccessToken.stubs(:read).returns('myaccesstoken')
          @mutation = File.read(File.join(FIXTURE_DIR, 'populate/product.graphql'))
        end

        def test_populate_calls_api_with_mutation
          ShopifyCli::Helpers::AdminAPI.expects(:query)
            .with(@context, @mutation)
            .returns(JSON.parse(File.read(File.join(FIXTURE_DIR, 'populate/product_data.json'))))
          ShopifyCli::API.expects(:gid_to_id).returns(12345678)
          Helpers::Haikunator.stubs(:title).returns('fake product')
          Resource.any_instance.stubs(:price).returns('1.00')
          @resource = Product.new(@context)
          @context.expects(:done).with(
            "fake product added to {{green:my-test-shop.myshopify.com}} at" \
            " {{underline:https://my-test-shop.myshopify.com/admin/products/12345678}}"
          )
          @resource.call(['-c 1'], nil)
        end
      end
    end
  end
end
