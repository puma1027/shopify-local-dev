# frozen_string_literal: true

require "project_types/script/test_helper"
require "project_types/script/layers/infrastructure/fake_extension_point_repository"

describe Script::Layers::Application::ExtensionPoints do
  include TestHelpers::FakeFS

  let(:script_name) { 'name' }
  let(:extension_point_type) { 'discount' }
  let(:deprecated_extension_point_type) { 'unit_limit_per_order' }
  let(:extension_point_repository) { Script::Layers::Infrastructure::FakeExtensionPointRepository.new }
  let(:extension_point) { extension_point_repository.get_extension_point(extension_point_type) }

  before do
    extension_point_repository.create_extension_point(extension_point_type)
    extension_point_repository.create_deprecated_extension_point(deprecated_extension_point_type)
    Script::Layers::Infrastructure::ExtensionPointRepository.stubs(:new).returns(extension_point_repository)
  end

  describe '.get' do
    describe 'when extension point exists' do
      it 'should return a valid extension point' do
        ep = Script::Layers::Application::ExtensionPoints.get(type: extension_point_type)
        assert_equal extension_point, ep
      end
    end

    describe 'when extension point does not exist' do
      it 'should raise InvalidExtensionPointError' do
        assert_raises(Script::Layers::Domain::Errors::InvalidExtensionPointError) do
          Script::Layers::Application::ExtensionPoints.get(type: 'invalid')
        end
      end
    end
  end

  describe '.types' do
    it 'should return an array of all types' do
      assert_equal %w(discount unit_limit_per_order), Script::Layers::Application::ExtensionPoints.types
    end
  end

  describe '.non_deprecated_types' do
    it 'should return an array of all non deprecated types' do
      assert_equal %w(discount), Script::Layers::Application::ExtensionPoints.non_deprecated_types
    end
  end

  describe '.deprecated_types' do
    it 'should return an array of all deprecated types' do
      assert_equal %w(unit_limit_per_order), Script::Layers::Application::ExtensionPoints.deprecated_types
    end
  end

  describe '.languages' do
    let(:type) { extension_point_type }
    subject { Script::Layers::Application::ExtensionPoints.languages(type: type) }

    describe 'when ep does not exist' do
      let(:type) { 'imaginary' }

      it 'should raise InvalidExtensionPointError' do
        assert_raises(Script::Layers::Domain::Errors::InvalidExtensionPointError) { subject }
      end
    end

    describe 'when beta language flag is enabled' do
      before do
        ShopifyCli::Feature.expects(:enabled?).with(:scripts_beta_languages).returns(true).at_least_once
      end

      it "should return all languages" do
        assert_equal ["assemblyscript", "rust"], subject
      end
    end

    describe 'when beta language flag is not enabled' do
      before do
        ShopifyCli::Feature.expects(:enabled?).with(:scripts_beta_languages).returns(false).at_least_once
      end

      it "should return only fully supported languages" do
        assert_equal ["assemblyscript"], subject
      end
    end
  end

  describe '.supported_language?' do
    let(:type) { extension_point_type }
    let(:language) { 'assemblyscript' }
    subject { Script::Layers::Application::ExtensionPoints.supported_language?(type: type, language: language) }

    describe 'when ep does not exist' do
      let(:type) { 'imaginary' }

      it 'should raise InvalidExtensionPointError' do
        assert_raises(Script::Layers::Domain::Errors::InvalidExtensionPointError) { subject }
      end
    end

    describe 'when beta language flag is enabled' do
      before do
        ShopifyCli::Feature.expects(:enabled?).with(:scripts_beta_languages).returns(true).at_least_once
      end

      describe "when asking about supported language" do
        let(:language) { 'assemblyscript' }

        it "should return true" do
          assert subject
        end
      end

      describe "when asking about beta language" do
        let(:language) { 'rust' }

        it "should return true" do
          assert subject
        end
      end

      describe "when user capitalizes supported language" do
        let(:language) { 'Rust' }

        it "should return true" do
          assert subject
        end
      end

      describe "when asking about unsupported language" do
        let(:language) { 'english' }

        it "should return false" do
          refute subject
        end
      end
    end

    describe 'when beta language flag is not enabled' do
      before do
        ShopifyCli::Feature.expects(:enabled?).with(:scripts_beta_languages).returns(false).at_least_once
      end

      describe "when asking about supported language" do
        let(:language) { 'assemblyscript' }

        it "should return true" do
          assert subject
        end
      end

      describe "when asking about beta language" do
        let(:language) { 'rust' }

        it "should return false" do
          refute subject
        end
      end

      describe "when user capitalizes supported language" do
        let(:language) { 'AssemblyScript' }

        it "should return true" do
          assert subject
        end
      end

      describe "when asking about unsupported language" do
        let(:language) { 'english' }

        it "should return false" do
          refute subject
        end
      end
    end
  end
end
