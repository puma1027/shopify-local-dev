# frozen_string_literal: true

require "project_types/script/test_helper"

describe Script::Layers::Infrastructure::Languages::AssemblyScriptProjectCreator do
  include TestHelpers::FakeFS

  let(:script_name) { "myscript" }
  let(:language) { "AssemblyScript" }
  let(:script_id) { "id" }
  let(:context) { TestHelpers::FakeContext.new }
  let(:script_api_type) { "discount" }
  let(:script_api) { Script::Layers::Domain::ScriptApi.new(script_api_type, script_api_config) }
  let(:project_creator) do
    Script::Layers::Infrastructure::Languages::AssemblyScriptProjectCreator
      .new(ctx: context, script_api: script_api, script_name: script_name, path_to_project: script_name)
  end
  let(:script_api_config) do
    {
      "assemblyscript" => {
        "package": "@shopify/extension-point-as-fake",
        "sdk-version": "*",
        "toolchain-version": "*",
      },
    }
  end
  let(:fake_capture2e_response) { [nil, OpenStruct.new(success?: true)] }

  before do
    context.mkdir_p(script_name)
  end

  describe ".setup_dependencies" do
    subject { project_creator.setup_dependencies }

    it "should write to package.json" do
      context.expects(:capture2e).returns([JSON.generate("2.0.0"), OpenStruct.new(success?: true)]).times(3)
      context.expects(:write).with do |_file, contents|
        payload = JSON.parse(contents)
        build = payload.dig("scripts", "build")
        expected = [
          "shopify-scripts-toolchain-as build --src src/shopify_main.ts",
          "--binary build/script.wasm --metadata build/metadata.json",
          "-- --lib node_modules --optimize --use Date=",
        ].join(" ")
        expected == build
      end

      subject
    end

    it "should fetch the latest extension point version if the package is not versioned" do
      context
        .expects(:capture2e)
        .with("npm --userconfig ./.npmrc config set @shopify:registry https://registry.npmjs.com")
        .returns(fake_capture2e_response)
      context
        .expects(:capture2e)
        .with("npm --userconfig ./.npmrc config set engine-strict true")
        .returns(fake_capture2e_response)
      context
        .expects(:capture2e)
        .with("npm show @shopify/extension-point-as-fake version --json")
        .once
        .returns([JSON.generate("2.0.0"), OpenStruct.new(success?: true)])

      sdk = mock
      sdk.expects(:sdk_version)
      sdk.expects(:toolchain_version)
      sdk.expects(:versioned?).once.returns(false)
      sdk.expects(:package).twice.returns("@shopify/extension-point-as-fake")
      script_api.expects(:sdks).times(5).returns(stub(all: [sdk], assemblyscript: sdk))

      subject
      version = JSON.parse(File.read("package.json")).dig("devDependencies", "@shopify/extension-point-as-fake")
      assert_equal "^2.0.0", version
    end

    it "should set the specified package version when the package is versioned" do
      context
        .expects(:capture2e)
        .with("npm --userconfig ./.npmrc config set @shopify:registry https://registry.npmjs.com")
        .returns(fake_capture2e_response)
      context
        .expects(:capture2e)
        .then.with("npm --userconfig ./.npmrc config set engine-strict true")
        .returns(fake_capture2e_response)

      context
        .expects(:capture2e)
        .with("npm show @shopify/extension-point-as-fake version --json")
        .never

      sdk = mock
      sdk.expects(:sdk_version)
      sdk.expects(:toolchain_version)
      sdk.expects(:package).once.returns("@shopify/extension-point-as-fake")
      sdk.expects(:versioned?).once.returns(true)
      sdk.expects(:version).once.returns("file:///path")
      script_api.expects(:sdks).times(5).returns(stub(all: [sdk], assemblyscript: sdk))

      subject
      version = JSON.parse(File.read("package.json")).dig("devDependencies", "@shopify/extension-point-as-fake")
      assert_equal "file:///path", version
    end

    it "should raise if the latest extension point version can't be fetched" do
      context
        .expects(:capture2e)
        .with("npm --userconfig ./.npmrc config set @shopify:registry https://registry.npmjs.com")
        .returns(fake_capture2e_response)
      context
        .expects(:capture2e)
        .then.with("npm --userconfig ./.npmrc config set engine-strict true")
        .returns(fake_capture2e_response)

      context
        .expects(:capture2e)
        .with("npm show @shopify/extension-point-as-fake version --json")
        .once
        .returns([JSON.generate(""), OpenStruct.new(success?: false)])

      sdk = mock
      sdk.expects(:sdk_version)
      sdk.expects(:toolchain_version)
      sdk.expects(:versioned?).once.returns(false)
      sdk.expects(:package).twice.returns("@shopify/extension-point-as-fake")
      script_api.expects(:sdks).times(5).returns(stub(all: [sdk], assemblyscript: sdk))

      assert_raises(Script::Layers::Infrastructure::Errors::SystemCallFailureError) { subject }
    end
  end

  describe ".bootstrap" do
    subject { project_creator.bootstrap }

    it "should delegate the bootstrapping process to the language toolchain" do
      context.expects(:capture2e)
        .with(
          "npx --no-install shopify-scripts-toolchain-as bootstrap --from #{script_api.type} --dest #{script_name}"
        )
        .returns(["", OpenStruct.new(success?: true)])

      subject
    end

    it "raises an error when the bootstrapping process fails to find the requested extension point" do
      context.expects(:capture2e)
        .with(
          "npx --no-install shopify-scripts-toolchain-as bootstrap --from #{script_api.type} --dest #{script_name}"
        )
        .returns(["", OpenStruct.new(success?: false)])

      assert_raises(Script::Layers::Infrastructure::Errors::SystemCallFailureError) { subject }
    end
  end

  describe "bootstrap extension points with domain" do
    subject { project_creator.bootstrap }

    let(:script_api_config_with_domain) { script_api_config.merge({ "domain" => "checkout" }) }
    let(:script_api) do
      Script::Layers::Domain::ScriptApi.new(script_api_type, script_api_config_with_domain)
    end

    it "should call the language toolchain with the appropriate domain arguments" do
      context.expects(:capture2e)
        .with(
          "npx --no-install shopify-scripts-toolchain-as bootstrap --from #{script_api.type} " \
          "--dest #{script_name} --domain checkout"
        )
        .returns(["", OpenStruct.new(success?: true)])

      subject
    end
  end

  describe "dependencies for extension points with domain" do
    subject { project_creator.setup_dependencies }

    let(:script_api_config_with_domain) { script_api_config.merge({ "domain" => "checkout" }) }
    let(:script_api) do
      Script::Layers::Domain::ScriptApi.new(script_api_type, script_api_config_with_domain)
    end

    it "should create the build command in the package.json with the appropriate domain arguments" do
      context.expects(:capture2e).once.returns([JSON.generate("2.0.0"), OpenStruct.new(success?: true)]).times(3)
      context.expects(:write).with do |_file, contents|
        payload = JSON.parse(contents)
        build = payload.dig("scripts", "build")
        expected = [
          "shopify-scripts-toolchain-as build --src src/shopify_main.ts --binary build/script.wasm",
          "--metadata build/metadata.json --domain checkout --ep discount",
          "-- --lib node_modules --optimize --use Date=",
        ].join(" ")
        expected == build
      end

      subject
    end
  end
end
