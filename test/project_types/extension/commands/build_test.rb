# frozen_string_literal: true
require 'test_helper'

module Extension
  module Commands
    class BuildTest < MiniTest::Test
      include TestHelpers::Partners
      include TestHelpers::FakeUI

      def setup
        super
        ShopifyCli::ProjectType.load_type(:extension)
      end

      def test_is_a_hidden_command
        assert Commands::Build.hidden?
      end

      def test_implements_help
        refute_empty(Build.help)
      end

      def test_uses_js_system_to_call_yarn_or_npm_commands
        ShopifyCli::JsSystem.any_instance
          .expects(:call)
          .with(yarn: Build::YARN_BUILD_COMMAND, npm: Build::NPM_BUILD_COMMAND)
          .returns(true)
          .once

        run_build
      end

      def test_aborts_and_informs_the_user_when_build_fails
        ShopifyCli::JsSystem.any_instance.stubs(:call).returns(false)
        @context.expects(:abort).with(@context.message('build.build_failure_message'))

        run_build
      end

      private

      def run_build(*args)
        Build.ctx = @context
        Build.call(args, 'build')
      end
    end
  end
end
