require "test_helper"

module ShopifyCli
  class PartnersAPITest < MiniTest::Test
    include TestHelpers::Project

    def test_query_calls_partners_api
      ShopifyCli::DB.expects(:get).with(:partners_exchange_token).returns('token123')
      api_stub = stub
      PartnersAPI.expects(:new).with(
        ctx: @context,
        token: "token123",
        url: "https://partners.shopify.com/api/cli/graphql",
      ).returns(api_stub)
      api_stub.expects(:query).with("query", variables: {}).returns("response")
      assert_equal "response", PartnersAPI.query(@context, "query")
    end

    def test_query_can_reauth
      Shopifolk.stubs(:check).returns(false)
      ShopifyCli::DB.expects(:get).with(:partners_exchange_token).returns('token123').twice

      api_stub = stub
      PartnersAPI.expects(:new).with(
        ctx: @context,
        token: "token123",
        url: "https://partners.shopify.com/api/cli/graphql",
      ).returns(api_stub).twice
      api_stub.expects(:query).with("query", variables: {}).returns("response")
      api_stub.expects(:query).raises(API::APIRequestUnauthorizedError)

      @oauth_client = mock
      ShopifyCli::IdentityAuth
        .expects(:new)
        .with(ctx: @context).returns(@oauth_client)
      @oauth_client
        .expects(:authenticate)

      PartnersAPI.query(@context, "query")
    end

    def test_query_fails_gracefully_without_partners_account
      ShopifyCli::DB.expects(:get).with(:partners_exchange_token).returns('token123')
      api_stub = stub
      PartnersAPI.expects(:new).with(
        ctx: @context,
        token: "token123",
        url: "https://partners.shopify.com/api/cli/graphql",
      ).returns(api_stub)
      api_stub.expects(:query).raises(API::APIRequestNotFoundError)
      @context.expects(:puts).with(@context.message("core.partners_api.error.account_not_found", ShopifyCli::TOOL_NAME))
      PartnersAPI.query(@context, "query")
    end

    def test_query
      ShopifyCli::DB.expects(:get).with(:partners_exchange_token).returns('token123')
      api_stub = stub
      PartnersAPI.expects(:new).with(
        ctx: @context,
        token: "token123",
        url: "https://partners.shopify.com/api/cli/graphql",
      ).returns(api_stub)
      api_stub.expects(:query).with("query", variables: {}).returns("response")
      assert_equal "response", PartnersAPI.query(@context, "query")
    end
  end
end
