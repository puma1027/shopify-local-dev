require 'shopify_cli'

module ShopifyCli
  module AppTypes
    class Node < AppType
      class << self
        def env_file
          <<~KEYS
            SHOPIFY_API_KEY={api_key}
            SHOPIFY_API_SECRET_KEY={secret}
            HOST={host}
            SHOP={shop}
            SCOPES={scopes}
          KEYS
        end

        def description
          'node embedded app'
        end

        def serve_command(_ctx)
          %W(
            HOST=#{Project.current.env.host}
            PORT=#{ShopifyCli::Tasks::Tunnel::PORT}
            npm run dev
          ).join(' ')
        end

        def generate
          {
            page: 'npm run-script generate-page --silent',
            billing_recurring: 'npm run-script generate-recurring-billing --silent',
            billing_one_time: 'npm run-script generate-one-time-billing --silent',
            webhook: 'npm run-script generate-webhook --silent',
          }
        end

        def open(ctx)
          ctx.system('open', "#{Project.current.env.host}/auth?shop=#{Project.current.env.shop}")
        end
      end

      def build(name)
        ShopifyCli::Tasks::Clone.call('https://github.com/Shopify/shopify-app-node.git', name)
        ShopifyCli::Finalize.request_cd(name)
        ShopifyCli::Tasks::JsDeps.call(ctx.root)

        begin
          ctx.rm_r(File.join(ctx.root, '.git'))
          ctx.rm_r(File.join(ctx.root, '.github'))
          ctx.rm(File.join(ctx.root, 'server', 'handlers', 'client.js'))
          ctx.rename(
            File.join(ctx.root, 'server', 'handlers', 'client.cli.js'),
            File.join(ctx.root, 'server', 'handlers', 'client.js')
          )
        rescue Errno::ENOENT => e
          ctx.debug(e)
        end

        puts CLI::UI.fmt(post_clone)
      end

      def check_dependencies
        check_npm_node
        check_npm_registry
      end

      def check_npm_node
        deps = ['node -v', 'npm -v']
        deps.each do |dep|
          dep_name = dep.split.first
          dep_link = dep_name == 'node' ? 'https://nodejs.org/en/download.' : 'https://www.npmjs.com/get-npm'
          version, stat = ctx.capture2e(dep)
          ctx.puts("{{green:✔︎}} #{dep_name} #{version}")
          next if stat.success?
          raise(ShopifyCli::Abort,
            "#{dep_name} is required to create an app project. Download at #{dep_link}")
        end
      end

      def check_npm_registry
        if ctx.getenv('DISABLE_NPM_REGISTRY_CHECK').nil?
          registry, _ = ctx.capture2('npm', 'config', 'get', '@shopify:registry')
          msg = <<~MSG
            You are not using the public npm registry for Shopify packages. This can cause issues with installing @shopify packages.
            Please run `npm config set @shopify:registry https://registry.yarnpkg.com and try this command again,
            or preface the command with `DISABLE_NPM_REGISTRY_CHECK=1`.
          MSG
          raise(ShopifyCli::Abort, msg) unless registry.include?('https://registry.yarnpkg.com')
        end
      end
    end
  end
end
