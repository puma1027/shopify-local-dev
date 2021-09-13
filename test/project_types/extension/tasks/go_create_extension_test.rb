# frozen_string_literal: true
require "test_helper"

module Extension
  module Tasks
    class GoCreateExtensionTest < MiniTest::Test
      def setup
        super
        ShopifyCli::ProjectType.load_type(:extension)
      end

      def test_go_create_extension_succeeds_with_no_errors
        assert_nothing_raised do
          Models::ServerConfig::Extension.expects(:build).with(
            template: "javascript",
            type: "checkout_ui_extension",
            root_dir: "test",
          ).returns(extension)

          server_config = Models::ServerConfig::Root.new(extensions: [extension])

          Models::ServerConfig::Root.expects(:new).returns(server_config).at_least_once

          CLI::Kit::System.expects(:capture3).returns("", nil, true)

          dev_server = Models::DevelopmentServer.new(executable: "fake")
          Models::DevelopmentServer.expects(:new).returns(dev_server) do |server|
            server.expects(:create).with(server_config).returns(true)
          end

          Tasks::GoCreateExtension.new(
            root_dir: "test",
            template: "javascript",
            type: "checkout_ui_extension",
          ).call
        end
      end

      private

      def extension
        renderer = Models::ServerConfig::DevelopmentRenderer.new(name: "@shopify/checkout-ui-extensions")
        entries = Models::ServerConfig::DevelopmentEntries.new(main: "src/index.js")
        development = Models::ServerConfig::Development.new(
          build_dir: "test",
          root_dir: "test",
          template: "javascript",
          renderer: renderer,
          entries: entries,
        )

        @extension ||= Models::ServerConfig::Extension.new(
          type: "checkout_ui_extension",
          uuid: "00000000-0000-0000-0000-000000000000",
          user: Models::ServerConfig::User.new,
          development: development
        )
      end
    end
  end
end
