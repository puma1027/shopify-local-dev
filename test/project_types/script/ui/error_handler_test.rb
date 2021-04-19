# frozen_string_literal: true

require "project_types/script/test_helper"

describe Script::UI::ErrorHandler do
  describe ".display_and_raise" do
    let(:failed_op) { "Operation didn't complete." }
    let(:cause_of_error) { "This is why it failed." }
    let(:help_suggestion) { "Perhaps this is what's wrong." }
    let(:ctx_root) { "/some/dir/here" }
    let(:ctx) { TestHelpers::FakeContext.new(root: ctx_root) }
    let(:ci?) { ctx.ci? }
    subject do
      Script::UI::ErrorHandler.display_and_raise(
        failed_op: failed_op, cause_of_error: cause_of_error, help_suggestion: help_suggestion
      )
    end

    describe "when failed operation message, cause of error, and help suggestion are all provided" do
      it "should abort with the cause of error and help suggestion" do
        if ci?
          $stderr.expects(:puts).with("✗ Error")
          $stderr.expects(:puts).with("#{failed_op} #{cause_of_error} #{help_suggestion}")
        else
          $stderr.expects(:puts).with("\e[0;31m✗ Error\e[0m")
          $stderr.expects(:puts).with("\e[0m#{failed_op} #{cause_of_error} #{help_suggestion}")
        end
        assert_raises(ShopifyCli::AbortSilent) do
          subject
        end
      end
    end

    describe "when failed operation message is missing" do
      let(:failed_op) { nil }
      it "should abort with the cause of error and help suggestion" do
        if ci?
          $stderr.expects(:puts).with("✗ Error")
          $stderr.expects(:puts).with("#{cause_of_error} #{help_suggestion}")
        else
          $stderr.expects(:puts).with("\e[0;31m✗ Error\e[0m")
          $stderr.expects(:puts).with("\e[0m#{cause_of_error} #{help_suggestion}")
        end
        assert_raises(ShopifyCli::AbortSilent) do
          subject
        end
      end
    end

    describe "when cause of error is missing" do
      let(:cause_of_error) { nil }
      it "should abort with the failed operation message and help suggestion" do
        if ci?
          $stderr.expects(:puts).with("✗ Error")
          $stderr.expects(:puts).with("#{failed_op} #{help_suggestion}")
        else
          $stderr.expects(:puts).with("\e[0;31m✗ Error\e[0m")
          $stderr.expects(:puts).with("\e[0m#{failed_op} #{help_suggestion}")
        end
        assert_raises(ShopifyCli::AbortSilent) do
          subject
        end
      end
    end

    describe "when help suggestion is missing" do
      let(:help_suggestion) { nil }
      it "should abort with the failed operation message and cause of error" do
        if ci?
          $stderr.expects(:puts).with("✗ Error")
          $stderr.expects(:puts).with("#{failed_op} #{cause_of_error}")
        else
          $stderr.expects(:puts).with("\e[0;31m✗ Error\e[0m")
          $stderr.expects(:puts).with("\e[0m#{failed_op} #{cause_of_error}")
        end
        assert_raises(ShopifyCli::AbortSilent) do
          subject
        end
      end
    end
  end

  describe ".pretty_print_and_raise" do
    let(:err) { nil }
    let(:failed_op) { "message" }
    subject { Script::UI::ErrorHandler.pretty_print_and_raise(err, failed_op: failed_op) }

    describe "when exception is not in list" do
      let(:err) { StandardError.new }

      it "should raise" do
        assert_raises(StandardError) { subject }
      end
    end

    describe "when exception is listed" do
      def should_call_display_and_raise
        Script::UI::ErrorHandler.expects(:display_and_raise).once
        subject
      end

      describe "when Errno::EACCESS" do
        let(:err) { Errno::EACCES.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when Errno::ENOSPC" do
        let(:err) { Errno::ENOSPC.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when Oauth::Error" do
        let(:err) { ShopifyCli::OAuth::Error.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when InvalidContextError" do
        let(:err) { Script::Errors::InvalidContextError.new("") }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when InvalidConfigProps" do
        let(:err) { Script::Errors::InvalidConfigProps.new("") }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when InvalidScriptNameError" do
        let(:err) { Script::Errors::InvalidScriptNameError.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when NoExistingAppsError" do
        let(:err) { Script::Errors::NoExistingAppsError.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when NoExistingOrganizationsError" do
        let(:err) { Script::Errors::NoExistingOrganizationsError.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when NoExistingStoresError" do
        let(:err) { Script::Errors::NoExistingStoresError.new(1) }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when ScriptProjectAlreadyExistsError" do
        let(:err) { Script::Errors::ScriptProjectAlreadyExistsError.new("/") }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when InvalidLanguageError" do
        let(:err) { Script::Errors::InvalidLanguageError.new("ruby", "discount") }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when MetadataValidationError" do
        let(:err) { Script::Layers::Domain::Errors::MetadataValidationError.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when InvalidConfigUiDefinitionError" do
        let(:err) { Script::Layers::Domain::Errors::InvalidConfigUiDefinitionError.new("filename") }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when MissingSpecifiedConfigUiDefinitionError" do
        let(:err) { Script::Layers::Domain::Errors::MissingSpecifiedConfigUiDefinitionError.new("filename") }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when InvalidExtensionPointError" do
        let(:err) { Script::Layers::Domain::Errors::InvalidExtensionPointError.new("") }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when ScriptNotFoundError" do
        let(:err) { Script::Layers::Domain::Errors::ScriptNotFoundError.new("ep type", "name") }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when AppNotInstalledError" do
        let(:err) { Script::Layers::Infrastructure::Errors::AppNotInstalledError.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when BuildError" do
        let(:err) { Script::Layers::Infrastructure::Errors::BuildError.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when ConfigUiSyntaxError" do
        let(:err) { Script::Layers::Infrastructure::Errors::ConfigUiSyntaxError.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when ConfigUiMissingKeysError" do
        let(:err) { Script::Layers::Infrastructure::Errors::ConfigUiMissingKeysError.new("file", "keys") }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when ConfigUiFieldsMissingKeysError" do
        let(:err) { Script::Layers::Infrastructure::Errors::ConfigUiFieldsMissingKeysError.new("file", "keys") }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when DependencyInstallError" do
        let(:err) { Script::Layers::Infrastructure::Errors::DependencyInstallError.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when EmptyResponseError" do
        let(:err) { Script::Layers::Infrastructure::Errors::EmptyResponseError.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when ForbiddenError" do
        let(:err) { Script::Layers::Infrastructure::Errors::ForbiddenError.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when GraphqlError" do
        let(:err) { Script::Layers::Infrastructure::Errors::GraphqlError.new([]) }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when ScriptRepushError" do
        let(:err) { Script::Layers::Infrastructure::Errors::ScriptRepushError.new("api_key") }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end

      describe "when ShopAuthenticationError" do
        let(:err) { Script::Layers::Infrastructure::Errors::ShopAuthenticationError.new }
        it "should call display_and_raise" do
          should_call_display_and_raise
        end
      end
    end
  end
end
