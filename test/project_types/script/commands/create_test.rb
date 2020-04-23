# frozen_string_literal: true

require 'project_types/script/test_helper'
require "project_types/script/layers/infrastructure/fake_script_repository"
require "project_types/script/layers/infrastructure/fake_extension_point_repository"

module Script
  module Commands
    class CreateTest < MiniTest::Test
      include TestHelpers::Partners
      include TestHelpers::FakeUI

      def setup
        @context = TestHelpers::FakeContext.new
        @language = 'ts'
        @script_name = 'name'
        @ep_type = 'discount'
      end

      def test_prints_help_with_no_name_argument
        @script_name = nil
        io = capture_io { perform_command }
        assert_match(CLI::UI.fmt(Script::Commands::Create.help), io.join)
      end

      def test_can_create_new_script
        Script::Layers::Application::CreateScript
          .expects(:call)
          .with(ctx: @context, language: @language, script_name: @script_name, extension_point_type: @ep_type)
          .returns(fake_script)

        @context
          .expects(:puts)
          .with(format(Script::Commands::Create::DIRECTORY_CHANGED_MSG, folder: fake_script.name))
        @context
          .expects(:puts)
          .with(format(Script::Commands::Create::OPERATION_SUCCESS_MESSAGE, script_id: fake_script.id))
        perform_command
      end

      private

      def perform_command
        run_cmd("create script --name=#{@script_name} --extension_point=#{@ep_type}")
      end

      def fake_script
        @fake_script ||= begin
           ep = Script::Layers::Infrastructure::FakeExtensionPointRepository.new.create_extension_point(@ep_type)
           Script::Layers::Infrastructure::FakeScriptRepository.new.create_script(@language, ep, @script_name)
         end
      end
    end
  end
end
