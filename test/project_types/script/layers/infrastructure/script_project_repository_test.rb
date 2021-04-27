# frozen_string_literal: true

require "project_types/script/test_helper"

describe Script::Layers::Infrastructure::ScriptProjectRepository do
  include TestHelpers::FakeFS

  let(:ctx) { TestHelpers::FakeContext.new }
  let(:instance) { Script::Layers::Infrastructure::ScriptProjectRepository.new(ctx: ctx) }

  let(:config_ui_repository) do
    Script::Layers::Infrastructure::ScriptProjectRepository::ConfigUiRepository.new(ctx: ctx)
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
        let(:expected_config_ui_filename) { "config-ui.yml" }
        let(:expected_config_ui_content) do
          "---\nversion: 1\ntype: single\ntitle: #{script_name}\ndescription: ''\nfields: []\n"
        end

        it "should create a new script project" do
          it_should_create_a_new_script_project
        end

        it "should create a config_ui_file" do
          capture_io { subject }

          config_ui = config_ui_repository.get(expected_config_ui_filename)

          refute_nil config_ui
          assert_equal expected_config_ui_filename, config_ui.filename
          assert_equal expected_config_ui_content, config_ui.content
          assert_equal config_ui.filename, subject.config_ui.filename
          assert_equal config_ui.content, subject.config_ui.content

          assert_equal expected_config_ui_filename, ShopifyCli::Project.current.config["config_ui_file"]
        end
      end

      describe "when no_config_ui is true" do
        let(:no_config_ui) { true }
        let(:expected_config_ui_filename) { nil }

        it "should create a new script project" do
          it_should_create_a_new_script_project
        end

        it "should not create a config_ui_file" do
          capture_io { subject }

          assert_nil subject.config_ui

          assert_nil ShopifyCli::Project.current.config["config_ui_file"]
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
    let(:config_ui_file) { "config-ui.yml" }
    let(:config_ui_content) { "---\nversion: 1" }
    let(:valid_config) do
      {
        "uuid" => uuid,
        "extension_point_type" => "tax_filter",
        "script_name" => "script_name",
        "config_ui_file" => config_ui_file,
      }
    end
    let(:actual_config) { valid_config }
    let(:current_project) do
      TestHelpers::FakeProject.new(directory: File.join(ctx.root, script_name), config: actual_config)
    end

    before do
      ShopifyCli::Project.stubs(:has_current?).returns(true)
      ShopifyCli::Project.stubs(:current).returns(current_project)
      config_ui_repository.create(config_ui_file, config_ui_content)
    end

    describe "when project config is valid" do
      it "should return the ScriptProject" do
        assert_equal current_project.directory, subject.id
        assert_nil subject.env
        assert_equal uuid, subject.uuid
        assert_equal script_name, subject.script_name
        assert_equal extension_point_type, subject.extension_point_type
        assert_equal language, subject.language
        assert_equal config_ui_file, subject.config_ui.filename
        assert_equal config_ui_content, subject.config_ui.content
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

      describe "when missing config_ui_file" do
        let(:actual_config) { hash_except(valid_config, "config_ui_file") }

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

  describe "#update_config" do
    subject { instance.update_config(**args) }

    let(:script_name) { "script_name" }
    let(:extension_point_type) { "tax_filter" }
    let(:language) { "assemblyscript" }
    let(:uuid) { "uuid" }
    let(:updated_uuid) { "updated_uuid" }
    let(:config_ui_file) { "config-ui.yml" }
    let(:valid_config) do
      {
        "project_type" => "script",
        "organization_id" => 1,
        "uuid" => uuid,
        "extension_point_type" => "tax_filter",
        "script_name" => "script_name",
        "config_ui_file" => config_ui_file,
      }
    end
    let(:actual_config) { valid_config }
    let(:current_project) do
      TestHelpers::FakeProject.new(directory: File.join(ctx.root, script_name), config: actual_config)
    end
    let(:args) do
      {
        uuid: updated_uuid
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
    end

    describe "when updating an immutable property" do
      let(:args) do
        {
          extension_point_type: 'a',
          language: 'b',
          script_name: 'c',
          project_type: 'd',
          organization_id: 'e',
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
        previous_config = ShopifyCli::Project.current.config
        assert subject
        updated_config = ShopifyCli::Project.current.config

        assert_equal hash_except(previous_config, "uuid"), hash_except(updated_config, "uuid")
        refute_equal previous_config["uuid"], updated_config["uuid"]
        assert_equal updated_uuid, updated_config["uuid"]
        assert_equal updated_uuid, subject["uuid"]
      end
    end
  end

  describe "ConfigUiRepository" do
    let(:instance) { Script::Layers::Infrastructure::ScriptProjectRepository::ConfigUiRepository.new(ctx: ctx) }

    describe "#create" do
      let(:filename) { "filename" }
      let(:content) { "content" }

      subject { instance.create(filename, content) }

      it "should write the content to the filename" do
        subject
        assert_equal content, File.read(filename)
      end

      it "should return a ConfigUi entity" do
        assert subject.is_a?(Script::Layers::Domain::ConfigUi)
      end
    end

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
          it "raises MissingSpecifiedConfigUiDefinitionError" do
            assert_raises(Script::Layers::Domain::Errors::MissingSpecifiedConfigUiDefinitionError) { subject }
          end
        end

        describe "when file exists" do
          before do
            File.write(filename, content)
          end

          describe "when content is invalid yaml" do
            let(:content) { "*" }

            it "raises InvalidConfigUiDefinitionError" do
              assert_raises(Script::Layers::Domain::Errors::InvalidConfigUiDefinitionError) { subject }
            end
          end

          describe "when content is valid yaml" do
            let(:content) { "---\nversion: 1" }

            it "returns the entity" do
              assert_equal filename, subject.filename
              assert_equal content, subject.content
            end
          end
        end
      end
    end
  end
end
