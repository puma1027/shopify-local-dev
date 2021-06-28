# frozen_string_literal: true
module Node
  class Command
    class Serve < ShopifyCli::SubCommand
      prerequisite_task ensure_project_type: :node
      prerequisite_task :ensure_env, :ensure_dev_store

      options do |parser, flags|
        parser.on("--host=HOST") do |h|
          flags[:host] = h.gsub('"', "")
        end
      end

      def call(*)
        project = ShopifyCli::Project.current
        url = options.flags[:host] || ShopifyCli::Tunnel.start(@ctx)
        @ctx.abort(@ctx.message("node.serve.error.host_must_be_https")) if url.match(/^https/i).nil?
        project.env.update(@ctx, :host, url)
        ShopifyCli::Tasks::UpdateDashboardURLS.call(
          @ctx,
          url: url,
          callback_url: "/auth/callback",
        )

        if project.env.shop
          project_url = "#{project.env.host}/auth?shop=#{project.env.shop}"
          @ctx.puts("\n" + @ctx.message("node.serve.open_info", project_url) + "\n")
        end

        CLI::UI::Frame.open(@ctx.message("node.serve.running_server")) do
          env = project.env.to_h
          env["PORT"] = ShopifyCli::Tunnel::PORT.to_s
          @ctx.system("npm run dev", env: env)
        end
      end

      def self.help
        ShopifyCli::Context.message("node.serve.help", ShopifyCli::TOOL_NAME)
      end

      def self.extended_help
        ShopifyCli::Context.message("node.serve.extended_help")
      end
    end
  end
end
