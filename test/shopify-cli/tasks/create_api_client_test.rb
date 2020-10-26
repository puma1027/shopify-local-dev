require 'test_helper'

module ShopifyCli
  module Tasks
    class CreateApiClientTest < MiniTest::Test
      include TestHelpers::Partners

      def test_call_will_query_partners_dashboard
        stub_partner_req(
          'create_app',
          variables: {
            org: 42,
            title: 'Test app',
            type: 'public',
            app_url: ShopifyCli::Tasks::CreateApiClient::DEFAULT_APP_URL,
            redir: ["http://127.0.0.1:3456"],
          },
          resp: {
            'data': {
              'appCreate': {
                'app': {
                  'apiKey': 'newapikey',
                  'apiSecretKeys': [{ 'secret': 'secret' }],
                },
              },
            },
          }
        )

        api_client = Tasks::CreateApiClient.call(
          @context,
          org_id: 42,
          title: 'Test app',
          type: 'public',
        )

        refute_nil(api_client)
        assert_equal('newapikey', api_client['apiKey'])
      end

      def test_call_will_return_any_user_errors
        stub_partner_req(
          'create_app',
          variables: {
            org: 42,
            title: 'Test app',
            type: 'public',
            app_url: ShopifyCli::Tasks::CreateApiClient::DEFAULT_APP_URL,
            redir: ["http://127.0.0.1:3456"],
          },
          resp: {
            'data': {
              'appCreate': {
                'userErrors': [
                  { 'field': 'title', 'message': 'is not a valid title' },
                ],
              },
            },
          }
        )

        err = assert_raises ShopifyCli::Abort do
          Tasks::CreateApiClient.call(
            @context,
            org_id: 42,
            title: 'Test app',
            type: 'public',
          )
        end
        assert_equal("{{x}} title is not a valid title", err.message)
      end
    end
  end
end
