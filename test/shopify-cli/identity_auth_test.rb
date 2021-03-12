require "test_helper"

module ShopifyCli
  class IdentityAuthTest < MiniTest::Test
    def test_authenticate
      client = oauth_client
      @context.expects(:open_url!)

      stub_auth_response(client)

      authorize_query = {
        client_id: client_id,
        scope: scopes(authorization_scopes),
        redirect_uri: IdentityAuth::REDIRECT_HOST,
        state: client.state_token,
        response_type: :code,
      }
      stub_request(:post, "#{endpoint}/authorize?#{URI.encode_www_form(authorize_query)}")

      token_query = {
        grant_type: :authorization_code,
        code: "mycode",
        redirect_uri: IdentityAuth::REDIRECT_HOST,
        client_id: client_id,
        code_verifier: client.code_verifier,
      }

      stub_request(:post, "#{endpoint}/token")
        .with(body: URI.encode_www_form(token_query))
        .to_return(status: 200, body: token_resp, headers: {})

      stub_exchange_token_calls

      client.authenticate

      assert_equal("accesstoken123", client.store.get(:identity_access_token))
      assert_equal("refreshtoken123", client.store.get(:identity_refresh_token))

      assert_expected_exchange_tokens(token_suffix: "exchangetoken123", client: client)
    end

    def test_refresh_exchange_token
      client = oauth_client(request_exchange: "123")
      client.store.set(
        :identity_access_token => "accesstoken123",
        :identity_refresh_token => "refreshtoken123",
        :partners_exchange_token => "partnerexchangetoken123",
        :shopify_exchange_token => "shopifyexchangetoken123",
        'storefront-renderer-production_exchange_token'.to_sym => "shopifyexchangetoken123"
      )

      stub_exchange_token_calls(exchange_token: "exchangetoken456")

      client.authenticate

      assert_expected_exchange_tokens(token_suffix: "exchangetoken456", client: client)
    end

    def test_refresh_access_token_fallback
      client = oauth_client(request_exchange: "123")
      client.store.set(
        identity_access_token: "accesstoken123",
        identity_refresh_token: "refreshtoken123",
        partners_exchange_token: "partnerexchangetoken123",
        shopify_exchange_token: "shopifyexchangetoken123",
      )

      stub_exchange_token_calls(status: 403)

      token_query = {
        grant_type: :refresh_token,
        access_token: "accesstoken123",
        refresh_token: "refreshtoken123",
        client_id: client_id,
      }
      token_resp = {
        access_token: "accesstoken456",
        refresh_token: "refreshtoken456",
      }.to_json

      stub_request(:post, "#{endpoint}/token")
        .with(body: URI.encode_www_form(token_query))
        .to_return(status: 200, body: token_resp, headers: {})

      stub_exchange_token_calls(exchange_token: "exchangetoken456", access_token: "accesstoken456")

      client.authenticate

      assert_equal("accesstoken456", client.store.get(:identity_access_token))
      assert_equal("refreshtoken456", client.store.get(:identity_refresh_token))

      assert_expected_exchange_tokens(token_suffix: "exchangetoken456", client: client)
    end

    def test_authenticate_with_invalid_request
      client = oauth_client
      @context.expects(:open_url!)

      stub_server(client, {
        "error" => "err",
        "error_description" => "error",
      })

      stub_request(:post, "#{endpoint}/authorize")
      assert_raises IdentityAuth::Error do
        client.authenticate
      end
    end

    def test_authenticate_with_invalid_code
      client = oauth_client(secret: "secret")
      code_verifier = "123456"
      @context.expects(:open_url!)
      stub_auth_response(client)

      authorize_query = {
        client_id: client_id,
        scope: scopes(authorization_scopes),
        redirect_uri: IdentityAuth::REDIRECT_HOST,
        state: client.state_token,
        response_type: :code,
      }
      stub_request(:post, "#{endpoint}/authorize?#{URI.encode_www_form(authorize_query)}")

      token_query = {
        grant_type: :authorization_code,
        code: "mycode",
        redirect_uri: IdentityAuth::REDIRECT_HOST,
        client_id: client_id,
        code_verifier: code_verifier,
      }

      stub_request(:post, "#{endpoint}/token")
        .with(body: URI.encode_www_form(token_query))
        .to_return(
          status: 400,
          body: '{ "error": "invalid_code", "error_description": "your code has expired or is invalid" }',
          headers: {},
        )

      assert_raises IdentityAuth::Error do
        client.authenticate
      end
    end

    private

    def assert_expected_exchange_tokens(token_suffix:, client:)
      ShopifyCli::IdentityAuth::APPLICATION_SCOPES.keys.each do |key|
        assert_equal(key + token_suffix, client.store.get("#{key}_exchange_token".to_sym))
      end
    end

    def stub_exchange_token_calls(exchange_token: "exchangetoken123", access_token: "accesstoken123", status: nil)
      ShopifyCli::IdentityAuth::APPLICATION_SCOPES.keys.each do |application|
        token_query = {
          grant_type: "urn:ietf:params:oauth:grant-type:token-exchange",
          requested_token_type: "urn:ietf:params:oauth:token-type:access_token",
          subject_token_type: "urn:ietf:params:oauth:token-type:access_token",
          client_id: client_id,
          audience: ShopifyCli::IdentityAuth::APPLICATION_CLIENT_IDS[application],
          scope: scopes(scopes_for(application)),
          subject_token: access_token,
        }
        if status
          stub_request(:post, "#{endpoint}/token")
            .with(body: URI.encode_www_form(token_query))
            .to_return(status: status)
        else
          stub_request(:post, "#{endpoint}/token")
            .with(body: URI.encode_www_form(token_query))
            .to_return(status: 200, body: { access_token: application + exchange_token }.to_json, headers: {})
        end
      end
    end

    def oauth_client(*)
      @oauth_client ||= begin
        db = ShopifyCli::DB.new(path: File.join(ShopifyCli::TEMP_DIR, ".test_db.pstore"))
        db.clear
        IdentityAuth.new(ctx: @context, store: db, code_verifier: "123456")
      end
    end

    def endpoint
      "https://accounts.shopify.com/oauth"
    end

    def client_id
      "fbdb2649-e327-4907-8f67-908d24cfd7e3"
    end

    def authorization_scopes
      ShopifyCli::IdentityAuth::APPLICATION_SCOPES.values.flatten
    end

    def scopes_for(name)
      ShopifyCli::IdentityAuth::APPLICATION_SCOPES[name]
    end

    def stub_auth_response(client)
      stub_server(client, {
        "code" => "mycode",
        "state" => client.state_token,
      })
    end

    def stub_server(client, resp)
      server = mock
      client.stubs(:server).returns(server)
      server.expects(:start)
      client.response_query = resp
    end

    def token_resp
      {
        access_token: "accesstoken123",
        refresh_token: "refreshtoken123",
      }.to_json
    end

    def scopes(additional_scopes = [])
      (["openid"] + additional_scopes).tap do |result|
        result << "employee" if ShopifyCli::Shopifolk.acting_as_shopify_organization?
      end.join(" ")
    end
  end
end
