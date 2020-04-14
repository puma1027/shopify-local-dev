require 'test_helper'

module ShopifyCli
  module Commands
    class ConnectTest < MiniTest::Test
      include TestHelpers::Partners

      def test_run
        response = [{
          "id" => 421,
          "businessName" => "one",
          "stores" => [{
            "shopDomain" => "store.myshopify.com",
          }],
          "apps" => [{
            "title" => "app",
            "apiKey" => 1234,
            "apiSecretKeys" => [{
              "secret" => 1233,
            }],
          }],
        }, {
          "id" => 422,
          "businessName" => "two",
          "stores" => [
            { "shopDomain" => "store2.myshopify.com", "shopName" => "foo" },
            { "shopDomain" => "store1.myshopify.com", "shopName" => "bar" },
          ],
          "apps" => [{
            "title" => "app",
            "apiKey" => 1235,
            "apiSecretKeys" => [{
              "secret" => 1234,
            }],
          }],
        }]
        ShopifyCli::Helpers::Organizations.stubs(:fetch_with_app).returns(response)
        CLI::UI::Prompt.expects(:ask).with('To which organization does this project belong?').returns(422)
        CLI::UI::Prompt.expects(:ask).with(
          'Which development store would you like to use?'
        ).returns('store.myshopify.com')
        Helpers::EnvFile.any_instance.stubs(:write)
        run_cmd('connect')
      end

      def test_no_prompt_if_one_app_and_org
        response = [{
          "id" => 421,
          "businessName" => "one",
          "stores" => [{
            "shopDomain" => "store.myshopify.com",
          }],
          "apps" => [{
            "title" => "app",
            "apiKey" => 1234,
            "apiSecretKeys" => [{
              "secret" => 1233,
            }],
          }],
        }]
        ShopifyCli::Helpers::Organizations.stubs(:fetch_with_app).returns(response)
        Helpers::EnvFile.any_instance.stubs(:write)
        run_cmd('connect')
      end
    end
  end
end
