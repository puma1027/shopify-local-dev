# frozen_string_literal: true

require "project_types/script/test_helper"

module Script
  module Commands
    class PushTest < MiniTest::Test
      def setup
        super
        @context = TestHelpers::FakeContext.new
        @api_key = "apikey"
        @force = true
        @env = ShopifyCli::Resources::EnvFile.new(api_key: @api_key, secret: "shh")
        @script_project_repo = TestHelpers::FakeScriptProjectRepository.new
        @script_project_repo.create(
          language: "assemblyscript",
          extension_point_type: "discount",
          script_name: "script_name",
          no_config_ui: false,
          env: @env
        )
        Script::Layers::Infrastructure::ScriptProjectRepository.stubs(:new).returns(@script_project_repo)
        ShopifyCli::ProjectType.load_type(:script)
      end

      def test_calls_push_script
        Tasks::EnsureEnv.expects(:call).with(@context)
        Layers::Application::PushScript.expects(:call).with(ctx: @context, force: @force)

        @context
          .expects(:puts)
          .with(@context.message("script.push.script_pushed", api_key: @api_key))
        perform_command
      end

      def test_help
        ShopifyCli::Context
          .expects(:message)
          .with("script.push.help", ShopifyCli::TOOL_NAME)
        Script::Commands::Push.help
      end

      def test_push_propagates_error_when_ensure_env_fails
        err_msg = "error message"
        Tasks::EnsureEnv
          .expects(:call)
          .with(@context)
          .raises(StandardError.new(err_msg))

        e = assert_raises(StandardError) { perform_command }
        assert_equal err_msg, e.message
      end

      def test_push_doesnt_print_api_key_when_it_hasnt_been_selected
        Tasks::EnsureEnv.expects(:call)
        @script_project_repo.expects(:get).returns(nil)

        UI::ErrorHandler.expects(:pretty_print_and_raise).with do |_error, args|
          assert_equal args[:failed_op], @context.message("script.push.error.operation_failed_no_api_key")
        end

        perform_command
      end

      def test_push_prints_api_key_when_it_has_been_selected
        Tasks::EnsureEnv.expects(:call)
        Layers::Application::PushScript.expects(:call).raises(StandardError.new)

        UI::ErrorHandler.expects(:pretty_print_and_raise).with do |_error, args|
          assert_equal args[:failed_op], @context.message(
            "script.push.error.operation_failed_with_api_key", api_key: @api_key
          )
        end

        perform_command
      end

      private

      def perform_command
        capture_io { run_cmd("push --force") }
      end
    end
  end
end
