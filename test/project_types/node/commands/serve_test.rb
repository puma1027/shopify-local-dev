# frozen_string_literal: true
require "project_types/node/test_helper"

module Node
  module Commands
    class ServeTest < MiniTest::Test
      include TestHelpers::FakeUI

      def setup
        super
        project_context("app_types", "node")
        ShopifyCli::Tasks::EnsureDevStore.stubs(:call)
        ShopifyCli::Tasks::EnsureProjectType.expects(:call).with(@context, :node)
        @context.stubs(:system)
      end

      def test_server_command
        ShopifyCli::Tunnel.stubs(:start).returns("https://example.com")
        ShopifyCli::Tasks::UpdateDashboardURLS.expects(:call)
        ShopifyCli::Resources::EnvFile.any_instance.expects(:update)
        @context.expects(:system).with(
          "npm run dev",
          env: {
            "SHOPIFY_API_KEY" => "mykey",
            "SHOPIFY_API_SECRET" => "mysecretkey",
            "SHOP" => "my-test-shop.myshopify.com",
            "SCOPES" => "read_products",
            "HOST" => "https://example.com",
            "PORT" => "8081",
          }
        )
        run_cmd("node serve")
      end

      def test_server_command_with_invalid_host_url
        ShopifyCli::Tunnel.stubs(:start).returns("garbage://example.com")
        ShopifyCli::Tasks::UpdateDashboardURLS.expects(:call).never
        ShopifyCli::Resources::EnvFile.any_instance.expects(:update).never
        @context.expects(:system).with(
          "npm run dev",
          env: {
            "SHOPIFY_API_KEY" => "mykey",
            "SHOPIFY_API_SECRET" => "mysecretkey",
            "SHOP" => "my-test-shop.myshopify.com",
            "SCOPES" => "read_products",
            "HOST" => "garbage://example.com",
            "PORT" => "8081",
          }
        ).never

        assert_raises ShopifyCli::Abort do
          run_cmd("node serve")
        end
      end

      def test_open_while_run
        ShopifyCli::Tunnel.stubs(:start).returns("https://example.com")
        ShopifyCli::Tasks::UpdateDashboardURLS.expects(:call)
        ShopifyCli::Resources::EnvFile.any_instance.expects(:update).with(
          @context, :host, "https://example.com"
        )
        @context.expects(:puts).with(
          "\n" +
          @context.message("node.serve.open_info", "https://example.com/auth?shop=my-test-shop.myshopify.com") +
          "\n"
        )
        run_cmd("node serve")
      end

      def test_update_env_with_host
        ShopifyCli::Tunnel.expects(:start).never
        ShopifyCli::Tasks::UpdateDashboardURLS.expects(:call)
        ShopifyCli::Resources::EnvFile.any_instance.expects(:update).with(
          @context, :host, "https://example-foo.com"
        )
        run_cmd('node serve --host="https://example-foo.com"')
      end

      def test_server_command_when_port_passed
        ShopifyCli::Tunnel.stubs(:start).returns("https://example.com")
        ShopifyCli::Tasks::UpdateDashboardURLS.expects(:call)
        ShopifyCli::Resources::EnvFile.any_instance.expects(:update)
        @context.expects(:system).with(
          "npm run dev",
          env: {
            "SHOPIFY_API_KEY" => "mykey",
            "SHOPIFY_API_SECRET" => "mysecretkey",
            "SHOP" => "my-test-shop.myshopify.com",
            "SCOPES" => "read_products",
            "HOST" => "https://example.com",
            "PORT" => "5000",
          }
        )
        run_cmd("node serve --port=5000")
      end
    end
  end
end
