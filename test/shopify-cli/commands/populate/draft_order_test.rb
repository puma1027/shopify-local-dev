require 'test_helper'

module ShopifyCli
  module Commands
    class Populate
      class DraftOrderTest < MiniTest::Test
        include TestHelpers::Context
        include TestHelpers::Schema

        def setup
          super
          @context.stubs(:project).returns(
            Project.at(File.join(FIXTURE_DIR, 'app_types/node'))
          )
          Helpers::AccessToken.stubs(:read).returns('myaccesstoken')
          ShopifyCli::Helpers::API.any_instance.stubs(:latest_api_version)
            .returns('2019-04')
          @mutation = File.read(File.join(FIXTURE_DIR, 'populate/draft_order.graphql'))
        end

        def test_populate_calls_api_with_mutation
          Helpers::Haikunator.stubs(:title).returns('fake order')
          Resource.any_instance.stubs(:price).returns('1.00')
          @resource = DraftOrder.new(ctx: @context, args: ['-c 1'])
          body = @resource.api.mutation_body(@mutation)
          stub_request(:post, "https://my-test-shop.myshopify.com/admin/api/2019-04/graphql.json")
            .with(body: body,
               headers: {
                 'Content-Type' => 'application/json',
                 'X-Shopify-Access-Token' => 'myaccesstoken',
               })
            .to_return(
              status: 200,
              body: File.read(File.join(FIXTURE_DIR, 'populate/draft_order_data.json')),
              headers: {}
            )
          @context.expects(:done).with(
            "draft order created: https://my-test-shop.myshopify.com/admin/draft_orders/12345678"
          )
          @resource.populate
        end
      end
    end
  end
end
