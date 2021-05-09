# frozen_string_literal: true
require "project_types/theme/test_helper"

module Theme
  module Commands
    class DeleteTest < MiniTest::Test
      include TestHelpers::FakeUI

      def setup
        super

        @ctx = ShopifyCli::Context.new
        @command = Theme::Command::Delete.new(@ctx)

        @config = mock("Config")
        @theme = stub(
          "Theme",
          id: 1234,
          name: "Test theme",
          shop: "test.myshopify.io",
          preview_url: "https://test.myshopify.io/",
          editor_url: "https://test.myshopify.io/",
        )
      end

      def test_delete_theme_ids
        ShopifyCli::Theme::Theme.expects(:new)
          .with(@ctx, id: 1234)
          .returns(@theme)

        @theme.expects(:delete)
        @ctx.expects(:done)

        @command.call([1234], "delete")
      end

      def test_delete_unexisting_theme_ids
        ShopifyCli::Theme::Theme.expects(:new)
          .with(@ctx, id: 1234)
          .returns(@theme)

        @theme.expects(:delete).raises(ShopifyCli::API::APIRequestNotFoundError)
        @ctx.expects(:puts)
        @ctx.expects(:done)

        @command.call([1234], "delete")
      end

      def test_delete_development_theme
        ShopifyCli::Theme::DevelopmentTheme.expects(:new)
          .with(@ctx)
          .returns(@theme)

        @theme.expects(:delete)
        @ctx.expects(:done)

        @command.options.flags[:development] = true
        @command.call([], "delete")
      end

      def test_delete_asks_to_select
        CLI::UI::Prompt.expects(:ask).returns(@theme)

        @theme.expects(:delete)
        @ctx.expects(:done)

        @command.call([], "delete")
      end
    end
  end
end
