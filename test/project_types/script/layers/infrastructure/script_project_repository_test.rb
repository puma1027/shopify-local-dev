# frozen_string_literal: true

require "project_types/script/test_helper"

describe Script::Layers::Infrastructure::ScriptProjectRepository do
  include TestHelpers::FakeFS

  let(:ctx) { TestHelpers::FakeContext.new }
  let(:instance) { Script::Layers::Infrastructure::ScriptProjectRepository.new(ctx: ctx) }

  let(:config_ui_repository) do
    Script::Layers::Infrastructure::ScriptProjectRepository::ScriptJsonRepository.new(ctx: ctx)
  end

  let(:deprecated_ep_types) { [] }
  let(:supported_languages) { ["assemblyscript"] }

  before do
    Script::Layers::Application::ExtensionPoints.stubs(:deprecated_types).returns(deprecated_ep_types)
    Script::Layers::Application::ExtensionPoints.stubs(:languages).returns(supported_languages)
  end

  describe "#create" do
    let(:script_name) { "script_name" }
    let(:extension_point_type) { "tax_filter" }
    let(:language) { "assemblyscript" }
    let(:no_config_ui) { false }

    before do
      dir = "/#{script_name}"
      ctx.mkdir_p(dir)
      ctx.chdir(dir)
    end

    subject do
      instance.create(
        script_name: script_name,
        extension_point_type: extension_point_type,
        language: language,
        no_config_ui: no_config_ui
      )
    end

    describe "failure" do
      describe "when extension point is deprecated" do
        let(:deprecated_ep_types) { [extension_point_type] }

        it "should raise DeprecatedEPError" do
          assert_raises(Script::Layers::Infrastructure::Errors::DeprecatedEPError) { subject }
        end
      end

      describe "when language is not supported" do
        let(:supported_languages) { ["rust"] }

        it "should raise InvalidLanguageError" do
          assert_raises(Script::Layers::Infrastructure::Errors::InvalidLanguageError) { subject }
        end
      end
    end

    describe "success" do
      def it_should_create_a_new_script_project
        capture_io { subject }

        assert_nil subject.env
        assert_nil subject.uuid
        assert_equal script_name, subject.script_name
        assert_equal extension_point_type, subject.extension_point_type
        assert_equal language, subject.language
      end

      describe "when no_config_ui is false" do
        let(:no_config_ui) { false }
        let(:expected_script_json_filename) { "script.json" }

        it "should create a new script project" do
          it_should_create_a_new_script_project
          assert_equal expected_script_json_filename, ShopifyCli::Project.current.config["script_json"]
        end
      end

      describe "when no_config_ui is true" do
        let(:no_config_ui) { true }
        let(:expected_script_json_filename) { nil }

        it "should create a new script project" do
          it_should_create_a_new_script_project
          assert_nil ShopifyCli::Project.current.config["script_json"]
        end
      end
    end
  end

  describe "#get" do
    subject { instance.get }

    let(:script_name) { "script_name" }
    let(:extension_point_type) { "tax_filter" }
    let(:language) { "assemblyscript" }
    let(:uuid) { "uuid" }
    let(:script_json) { "script.json" }
    let(:script_json_content) do
      {
        "version" => "1",
        "configurationUi" => true,
        "configuration" => {
          "type": "single",
          "schema": [
            {
              "key": "configurationKey",
              "name": "My configuration field",
              "type": "single_line_text_field",
              "helpText": "This is some help text",
              "defaultValue": "This is a default value",
            },
          ],
        },
      }
    end
    let(:valid_config) do
      {
        "extension_point_type" => "tax_filter",
        "script_name" => "script_name",
        "script_json" => script_json,
      }
    end
    let(:actual_config) { valid_config }
    let(:current_project) do
      TestHelpers::FakeProject.new(directory: File.join(ctx.root, script_name), config: actual_config)
    end

    before do
      ShopifyCli::Project.stubs(:has_current?).returns(true)
      ShopifyCli::Project.stubs(:current).returns(current_project)
      ctx.write(script_json, script_json_content.to_json)
    end

    describe "when project config is valid" do
      describe "when env is empty" do
        it "should have empty env values" do
          assert_nil subject.env
          assert_nil subject.uuid
          assert_nil subject.api_key
        end
      end

      describe "when env has values" do
        let(:uuid) { "uuid" }
        let(:api_key) { "api_key" }
        let(:env) { ShopifyCli::Resources::EnvFile.new(api_key: api_key, secret: "foo", extra: { "UUID" => uuid }) }

        it "should provide access to the env values" do
          ShopifyCli::Project.any_instance.expects(:env).returns(env).at_least_once

          assert_equal env, subject.env
          assert_equal uuid, subject.uuid
          assert_equal api_key, subject.api_key
        end
      end

      it "should return the ScriptProject" do
        assert_equal current_project.directory, subject.id
        assert_equal script_name, subject.script_name
        assert_equal extension_point_type, subject.extension_point_type
        assert_equal language, subject.language
        assert_equal script_json, subject.script_json.filename
        assert_equal script_json_content["version"], subject.script_json.version
        assert_equal script_json_content["version"], subject.script_json.version
        assert_equal script_json_content["configurationUi"], subject.script_json.configuration_ui
        assert_equal script_json_content["configuration"].to_json, subject.script_json.configuration.to_json
      end
    end

    describe "when extension point is deprecated" do
      let(:deprecated_ep_types) { [extension_point_type] }

      it "should raise DeprecatedEPError" do
        assert_raises(Script::Layers::Infrastructure::Errors::DeprecatedEPError) { subject }
      end
    end

    describe "when language is not supported" do
      let(:supported_languages) { ["rust"] }

      it "should raise InvalidLanguageError" do
        assert_raises(Script::Layers::Infrastructure::Errors::InvalidLanguageError) { subject }
      end
    end

    describe "when project is missing metadata" do
      def hash_except(config, *keys)
        config.slice(*(config.keys - keys))
      end

      describe "when missing extension_point_type" do
        let(:actual_config) { hash_except(valid_config, "extension_point_type") }

        it "should raise InvalidContextError" do
          assert_raises(Script::Layers::Infrastructure::Errors::InvalidContextError) { subject }
        end
      end

      describe "when missing script_name" do
        let(:actual_config) { hash_except(valid_config, "script_name") }

        it "should raise InvalidContextError" do
          assert_raises(Script::Layers::Infrastructure::Errors::InvalidContextError) { subject }
        end
      end

      describe "when missing script_json" do
        let(:actual_config) { hash_except(valid_config, "script_json") }

        it "should succeed" do
          assert subject
        end
      end

      describe "when missing uuid" do
        let(:actual_config) { hash_except(valid_config, "uuid") }

        it "should succeed" do
          assert subject
          assert_nil subject.uuid
        end
      end
    end
  end

  describe "#update_env" do
    subject { instance.update_env(**args) }

    let(:script_name) { "script_name" }
    let(:extension_point_type) { "tax_filter" }
    let(:language) { "assemblyscript" }
    let(:uuid) { "uuid" }
    let(:updated_uuid) { "updated_uuid" }
    let(:script_json) { "script.json" }
    let(:env) { ShopifyCli::Resources::EnvFile.new(api_key: "123", secret: "foo", extra: env_extra) }
    let(:env_extra) { { "uuid" => "original_uuid", "something" => "else" } }
    let(:valid_config) do
      {
        "project_type" => "script",
        "organization_id" => 1,
        "uuid" => uuid,
        "extension_point_type" => "tax_filter",
        "script_name" => "script_name",
        "script_json" => script_json,
      }
    end
    let(:args) do
      {
        uuid: updated_uuid,
      }
    end

    before do
      dir = "/#{script_name}"
      ctx.mkdir_p(dir)
      ctx.chdir(dir)

      instance.create(
        script_name: script_name,
        extension_point_type: extension_point_type,
        language: language,
        no_config_ui: true
      )
      ShopifyCli::Project.any_instance.expects(:env).returns(env).at_least_once
    end

    describe "when updating an immutable property" do
      let(:args) do
        {
          extension_point_type: "a",
          language: "b",
          script_name: "c",
          project_type: "d",
          organization_id: "e",
        }
      end

      it "should do nothing" do
        previous_config = ShopifyCli::Project.current.config
        assert subject
        updated_config = ShopifyCli::Project.current.config
        assert_equal previous_config, updated_config
      end
    end

    describe "when updating uuid" do
      def hash_except(config, *keys)
        config.slice(*(config.keys - keys))
      end

      it "should update the property" do
        previous_env = ShopifyCli::Project.current.env.to_h
        assert subject
        ShopifyCli::Project.clear
        updated_env = ShopifyCli::Project.current.env.to_h

        assert_equal hash_except(previous_env, "UUID"), hash_except(updated_env, "UUID")
        refute_equal previous_env["UUID"], updated_env["UUID"]
        assert_equal updated_uuid, updated_env["UUID"]
        assert_equal updated_uuid, subject.uuid
      end
    end
  end

  describe "ScriptJsonRepository" do
    let(:instance) { Script::Layers::Infrastructure::ScriptProjectRepository::ScriptJsonRepository.new(ctx: ctx) }

    describe "#get" do
      subject { instance.get(filename) }

      describe "when filename is empty" do
        let(:filename) { nil }

        it "should return nil" do
          assert_nil subject
        end
      end

      describe "when filename is not empty" do
        let(:filename) { "filename" }

        describe "when file does not exist" do
          it "raises MissingSpecifiedScriptJsonDefinitionError" do
            assert_raises(Script::Layers::Domain::Errors::MissingSpecifiedScriptJsonDefinitionError) { subject }
          end
        end

        describe "when file exists" do
          before do
            File.write(filename, content)
          end

          describe "when content is invalid yaml" do
            let(:content) { "*" }

            it "raises InvalidScriptJsonDefinitionError" do
              assert_raises(Script::Layers::Domain::Errors::InvalidScriptJsonDefinitionError) { subject }
            end
          end

          describe "when content is valid yaml" do
            let(:version) { "1" }
            let(:content) { { "version" => version }.to_json }

            it "returns the entity" do
              assert_equal filename, subject.filename
              assert_equal version, subject.version
            end
          end
        end
      end
    end
  end
end
