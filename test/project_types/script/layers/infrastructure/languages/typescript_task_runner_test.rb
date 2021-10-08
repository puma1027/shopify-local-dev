
require "project_types/script/test_helper"

describe Script::Layers::Infrastructure::Languages::TypeScriptTaskRunner do
  include TestHelpers::FakeFS

  BELOW_NODE_VERSION = "v14.4.0"
  EXACT_NODE_VERSION = "v14.5.0"
  ABOVE_NODE_VERSION = "v14.6.0"

  ABOVE_NPM_VERSION = "5.2.1"
  EXACT_NPM_VERSION = "5.2.0"

  let(:ctx) { TestHelpers::FakeContext.new }
  let(:script_name) { "foo" }
  let(:language) { "TypeScript" }
  let(:library_name) { "@shopify/extension-point-as-fake" }
  let(:runner) { Script::Layers::Infrastructure::Languages::TypeScriptTaskRunner.new(ctx, script_name) }
  let(:command_runner) { Script::Layers::Infrastructure::CommandRunner }
  let(:package_json) do
    {
      scripts: {
        build: "javy build/index.js -o build/index.wasm",
      },
    }
  end

  describe ".build" do
    subject { runner.build }

    it "should raise an error if no build script is defined" do
      File.expects(:read).with("package.json").once.returns(JSON.generate(package_json.delete(:scripts)))
      assert_raises(Script::Layers::Infrastructure::Errors::BuildScriptNotFoundError) do
        subject
      end
    end

    it "should raise an error if the build script is not compliant" do
      package_json[:scripts][:build] = ""
      File.expects(:read).with("package.json").once.returns(JSON.generate(package_json))
      assert_raises(Script::Layers::Infrastructure::Errors::InvalidBuildScriptError) do
        subject
      end
    end

    it "should raise an error if the generated web assembly is not found" do
      ctx.write("package.json", JSON.generate(package_json))
      ctx
        .expects(:capture2e)
        .with("npm run build")
        .once
        .returns(["output", mock(success?: true)])

      ctx
        .expects(:capture2e)
        .with("npm run gen-metadata")
        .once
        .returns(["output", mock(success?: true)])

      assert_raises(Script::Layers::Infrastructure::Errors::WebAssemblyBinaryNotFoundError) { subject }
    end

    describe "when index.wasm exists" do
      let(:wasm) { "some compiled code" }
      let(:wasmfile) { "build/index.wasm" }

      before do
        ctx.write("package.json", JSON.generate(package_json))
        ctx.mkdir_p(File.dirname(wasmfile))
        ctx.write(wasmfile, wasm)
      end

      it "triggers the compilation and metadata generation processes" do
        ctx
          .expects(:capture2e)
          .with("npm run build")
          .once
          .returns(["output", mock(success?: true)])

        ctx
          .expects(:capture2e)
          .with("npm run gen-metadata")
          .once
          .returns(["output", mock(success?: true)])

        assert ctx.file_exist?(wasmfile)
        assert_equal wasm, subject
        refute ctx.file_exist?(wasmfile)
      end
    end

    it "should raise error without command output on failure" do
      output = "error_output"
      File.expects(:read).with("package.json").once.returns(JSON.generate(package_json))
      File.expects(:read).never
      ctx
        .stubs(:capture2e)
        .returns([output, mock(success?: false)])

      assert_raises(Script::Layers::Infrastructure::Errors::SystemCallFailureError, output) do
        subject
      end
    end
  end

  describe ".project_dependencies_installed?" do
    subject { runner.project_dependencies_installed? }

    before do
      FileUtils.mkdir_p("node_modules")
    end

    it "should return true if node_modules folder exists" do
      assert subject
    end

    it "should return false if node_modules folder does not exists" do
      Dir.stubs(:exist?).returns(false)
      refute subject
    end
  end

  describe ".install_dependencies" do
    subject { runner.install_dependencies }

    describe "when npm version and node are above minimum" do
      def stub_tool_versions(npm:, node:)
        ctx.stubs(:capture2e)
          .with("npm", "--version")
          .returns([npm, mock(success?: true)])
        ctx.stubs(:capture2e)
          .with("node", "--version")
          .returns([node, mock(success?: true)])
      end

      describe "when npm packages fail to install" do
        it "should raise error" do
          stub_tool_versions(npm: EXACT_NPM_VERSION, node: EXACT_NODE_VERSION)
          ctx.expects(:capture2e)
            .with("npm install --no-audit --no-optional --legacy-peer-deps --loglevel error")
            .returns([nil, mock(success?: false)])
          assert_raises Script::Layers::Infrastructure::Errors::DependencyInstallationError do
            subject
          end
        end
      end

      describe "when npm packages install" do
        it "should successfully install" do
          stub_tool_versions(npm: EXACT_NPM_VERSION, node: EXACT_NODE_VERSION)
          ctx.expects(:capture2e)
            .with("npm install --no-audit --no-optional --legacy-peer-deps --loglevel error")
            .returns([nil, mock(success?: true)])
          subject
        end
      end

      describe "when capture2e fails" do
        it "should raise error" do
          msg = "error message"
          ctx.expects(:capture2e)
            .with("npm", "--version")
            .returns([EXACT_NPM_VERSION, mock(success?: true)])
          ctx.expects(:capture2e)
            .with("node", "--version")
            .returns([EXACT_NODE_VERSION, mock(success?: true)])
          ctx.expects(:capture2e)
            .with("npm install --no-audit --no-optional --legacy-peer-deps --loglevel error")
            .returns([msg, mock(success?: false)])
          assert_raises Script::Layers::Infrastructure::Errors::DependencyInstallationError, msg do
            subject
          end
        end
      end
    end
  end

  describe ".metadata" do
    subject { runner.metadata }

    describe "when metadata file is present and valid" do
      let(:metadata_json) do
        JSON.dump(
          {
            schemaVersions: {
              example: { major: "1", minor: "0" },
            },
          },
        )
      end

      it "should return a proper metadata object" do
        File.expects(:read).with("build/metadata.json").once.returns(metadata_json)

        ctx
          .expects(:file_exist?)
          .with("build/metadata.json")
          .once
          .returns(true)

        assert subject
      end
    end

    describe "when metadata file is missing" do
      it "should raise an exception" do
        assert_raises(Script::Layers::Domain::Errors::MetadataNotFoundError) do
          subject
        end
      end
    end
  end

  describe ".check_system_dependencies!" do
    subject { runner.check_system_dependencies! }

    describe "when npm is not installed" do
      it "should raise error" do
        ctx.expects(:capture2e)
          .with("npm", "--version")
          .returns([nil, mock(success?: false)])
        assert_raises Script::Layers::Infrastructure::Errors::NoDependencyInstalledError do
          subject
        end
      end
    end

    describe "when node is not installed" do
      it "should raise error" do
        ctx.expects(:capture2e)
          .with("npm", "--version")
          .returns([EXACT_NODE_VERSION, mock(success?: true)])
        ctx.expects(:capture2e)
          .with("node", "--version")
          .returns([nil, mock(success?: false)])
        assert_raises Script::Layers::Infrastructure::Errors::NoDependencyInstalledError do
          subject
        end
      end
    end

    describe "when npm version is below minimum" do
      it "should raise error" do
        ctx.expects(:capture2e)
          .with("npm", "--version")
          .returns([nil, mock(success?: false)])

        assert_raises Script::Layers::Infrastructure::Errors::NoDependencyInstalledError do
          subject
        end
      end
    end

    def stub_tool_versions(npm:, node:)
      ctx.stubs(:capture2e)
        .with("npm", "--version")
        .returns([npm, mock(success?: true)])
      ctx.stubs(:capture2e)
        .with("node", "--version")
        .returns([node, mock(success?: true)])
    end

    describe "when npm version is above minimum" do
      describe "when node version is below minimum" do
        it "should raise error" do
          stub_tool_versions(npm: ABOVE_NPM_VERSION, node: BELOW_NODE_VERSION)
          assert_raises Script::Layers::Infrastructure::Errors::MissingDependencyVersionError do
            subject
          end
        end
      end

      describe "when node version is above minimum" do
        it "should install successfully" do
          stub_tool_versions(npm: ABOVE_NPM_VERSION, node: ABOVE_NODE_VERSION)
          subject
        end
      end

      describe "when node version is the exact version" do
        it "should install successfully" do
          stub_tool_versions(npm: ABOVE_NPM_VERSION, node: EXACT_NODE_VERSION)
          subject
        end
      end
    end

    describe "when npm version is exactly the version" do
      describe "when node version is below minimum" do
        it "should raise error" do
          stub_tool_versions(npm: EXACT_NPM_VERSION, node: BELOW_NODE_VERSION)
          assert_raises Script::Layers::Infrastructure::Errors::MissingDependencyVersionError do
            subject
          end
        end
      end

      describe "when node version is above minimum" do
        it "should install successfully" do
          stub_tool_versions(npm: EXACT_NPM_VERSION, node: ABOVE_NODE_VERSION)
          subject
        end
      end

      describe "when node version is the exact version" do
        it "should install successfully" do
          stub_tool_versions(npm: EXACT_NPM_VERSION, node: EXACT_NODE_VERSION)
          subject
        end
      end
    end
  end

  describe ".library_version" do
    subject { runner.library_version(library_name) }

    describe "when the package is in the dependencies list" do
      it "should return a valid version number" do
        command_runner.any_instance.stubs(:call)
          .with("npm -s list --json")
          .returns(
            {
              "dependencies" => {
                library_name => {
                  "version" => "1.3.7",
                },
              },
            }.to_json
          )
        assert_equal "1.3.7", subject
      end
    end

    describe "when the package is not in the dependencies list" do
      it "should return an error" do
        command_runner.any_instance.stubs(:call)
          .with("npm -s list --json")
          .returns(
            {
              "dependencies" => {},
            }.to_json,
          )
        assert_raises Script::Layers::Infrastructure::Errors::APILibraryNotFoundError do
          subject
        end
      end
    end

    describe "when CommandRunner raises SystemCallFailureError" do
      describe "when error is not json" do
        it "should re-raise SystemCallFailureError" do
          cmd = "npm -s list --json"
          command_runner.any_instance.stubs(:call)
            .with(cmd)
            .raises(Script::Layers::Infrastructure::Errors::SystemCallFailureError.new(
              out: "some non-json parsable error output",
              cmd: cmd
            ))

          assert_raises Script::Layers::Infrastructure::Errors::SystemCallFailureError do
            subject
          end
        end
      end

      describe "when error is json, but doesn't contain the expected structure" do
        it "should re-raise SystemCallFailureError" do
          cmd = "npm -s list --json"
          command_runner.any_instance.stubs(:call)
            .with(cmd)
            .raises(Script::Layers::Infrastructure::Errors::SystemCallFailureError.new(
              out: {
                "not what we expected" => {},
              }.to_json,
              cmd: cmd
            ))
          assert_raises Script::Layers::Infrastructure::Errors::SystemCallFailureError do
            subject
          end
        end
      end

      describe "when error contains expected versioning data" do
        it "should rescue SystemCallFailureError if the library version is present" do
          cmd = "npm -s list --json"
          command_runner.any_instance.stubs(:call)
            .with(cmd)
            .raises(Script::Layers::Infrastructure::Errors::SystemCallFailureError.new(
              out: {
                "dependencies" => {
                  library_name => {
                    "version" => "1.3.7",
                  },
                },
              }.to_json,
              cmd: cmd
            ))
          assert_equal "1.3.7", subject
        end
      end
    end
  end
end
