# frozen_string_literal: true
module Rails
  module Commands
    class Serve < ShopifyCli::Command
      prerequisite_task :ensure_env, :ensure_test_shop

      options do |parser, flags|
        parser.on('--host=HOST') do |h|
          flags[:host] = h.gsub('"', '')
        end
      end

      def call(*)
        project = ShopifyCli::Project.current
        url = options.flags[:host] || ShopifyCli::Tunnel.start(@ctx)
        @ctx.abort("{{red:HOST must be a HTTPS url.}}") if url.match(/^https/i).nil?
        project.env.update(@ctx, :host, url)
        ShopifyCli::Tasks::UpdateDashboardURLS.call(
          @ctx,
          url: url,
          callback_url: "/auth/shopify/callback",
        )
        if @ctx.mac? && project.env.shop
          @ctx.puts("{{*}} Press {{yellow: Control-T}} to open this project in {{green:#{project.env.shop}}} ")

          # Reset any previous SIGINFO handling we had so the only action we take is opening the URL
          trap('INFO', 'DEFAULT')
          @ctx.on_siginfo do
            @ctx.open_url!("#{project.env.host}/login?shop=#{project.env.shop}")
          end
        end
        Gem.gem_home(@ctx)
        CLI::UI::Frame.open('Running server...') do
          env = ShopifyCli::Project.current.env.to_h
          env.delete('HOST')
          env['PORT'] = ShopifyCli::Tunnel::PORT.to_s
          @ctx.system('bin/rails server', env: env)
        end
      end

      def self.help
        <<~HELP
          Start a local development rails server for your project, as well as a public ngrok tunnel to your localhost.
            Usage: {{command:#{ShopifyCli::TOOL_NAME} serve}}
        HELP
      end

      def self.extended_help
        <<~HELP
          {{bold:Options:}}
            {{cyan:--host=HOST}}: Bypass running tunnel and use custom host. HOST must be HTTPS url.
        HELP
      end
    end
  end
end
