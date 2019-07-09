require 'test_helper'

module ShopifyCli
  module AppTypes
    class NodeBuildTest < MiniTest::Test
      def setup
        @context = TestHelpers::FakeContext.new(root: Dir.mktmpdir, env: {})
        @app = ShopifyCli::AppTypes::Node.new(ctx: @context)
      end

      def test_build_creates_app
        ShopifyCli::Tasks::Clone.stubs(:call).with(
          'https://github.com/Shopify/shopify-app-node.git',
          'test-app',
        )
        ShopifyCli::Tasks::JsDeps.stubs(:call).with(@context.root)
        @context.expects(:rm_r).with(File.join(@context.root, '.git'))
        @context.expects(:rm_r).with(File.join(@context.root, '.github'))
        @context.expects(:rm).with(File.join(@context.root, 'server', 'handlers', 'client.js'))
        io = capture_io do
          @app.build('test-app')
        end
        output = io.join

        assert_match(
          CLI::UI.fmt('Run {{command:shopify serve}} to start the local development server'),
          output
        )
      end

      def test_check_dependencies_command
        @context.expects(:capture2).with('npm', 'config', 'get', '@shopify:registry').returns(
          ['https://registry.yarnpkg.com', nil]
        )
        @context.expects(:capture2e).with(
          'node -v'
        ).returns(['8.0.0', mock(success?: true)])
        @context.expects(:capture2e).with(
          'npm -v'
        ).returns(['1', mock(success?: true)])

        io = capture_io do
          @app.check_dependencies
        end
        output = io.join
        assert_match('8.0.0', output)
      end

      def test_check_npm_node_command_error
        @app.stubs(:check_npm_registry)
        @context.expects(:capture2e).with(
          'node -v'
        ).returns([nil, mock(success?: false)])
        assert_raises ShopifyCli::Abort do
          capture_io do
            @app.check_dependencies
          end
        end
      end

      def test_check_dependencies_raises_on_non_public_npm_repo
        @context.expects(:capture2).with('npm', 'config', 'get', '@shopify:registry').returns(
          ['https://packages.private.io', nil]
        )
        @app.stubs(:check_npm_node)
        assert_raises ShopifyCli::Abort do
          capture_io do
            @app.check_dependencies
          end
        end
      end

      def test_check_dependencies_does_not_raise_on_non_public_npm_repo_with_override
        @context.setenv('DISABLE_NPM_REGISTRY_CHECK', '1')
        @app.stubs(:check_npm_node)
        assert_nothing_raised do
          capture_io do
            @app.check_dependencies
          end
        end
      end

      def test_build_does_not_error_on_missing_git_dir
        ShopifyCli::Tasks::Clone.stubs(:call).with(
          'https://github.com/Shopify/shopify-app-node.git',
          'test-app',
        )
        ShopifyCli::Tasks::JsDeps.stubs(:call).with(@context.root)
        @app.build('test-app')
      end
    end

    class NodeTest < MiniTest::Test
      include TestHelpers::Project
      include TestHelpers::Constants

      def setup
        project_context('app_types', 'node')
        @app = ShopifyCli::AppTypes::Node.new(ctx: @context)
      end

      def test_server_command
        @context.app_metadata[:host] = 'https://example.com'
        cmd = ShopifyCli::Commands::Serve.new(@context)
        @context.expects(:system).with(
          "HOST=https://example.com PORT=8081 npm run dev"
        )
        cmd.call([], nil)
      end

      def test_open_command
        cmd = ShopifyCli::Commands::Open.new(@context)
        @context.expects(:system).with(
          'open',
          'https://example.com/auth?shop=my-test-shop.myshopify.com'
        )
        cmd.call([], nil)
      end
    end
  end
end
