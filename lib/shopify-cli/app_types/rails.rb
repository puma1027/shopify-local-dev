# frozen_string_literal: true
require 'shopify_cli'

module ShopifyCli
  module AppTypes
    class Rails < ShopifyCli::Task
      def call(*args)
        @name = args.shift
        @dir = File.join(Dir.pwd, @name)
        generate
      end

      def ctx
        @ctx ||= ShopifyCli::Context.new
      end

      def self.description
        'rails embedded app'
      end

      def rails_installed?
        ShopifyCli::Helpers::GemHelper.installed?(ctx, 'rails')
      end

      protected

      def generate
        unless rails_installed?
          ShopifyCli::Helpers::GemHelper.install!(ctx, 'rails')
        end
        ctx.system('rails', 'new', @name)
        ctx.system('echo', '"gem \'shopify_app\'"', '>>', 'Gemfile')
        ctx.system('bundle', 'install', chdir: @dir)
        api_key = CLI::UI.ask('What is your Shopify API Key')
        api_secret = CLI::UI.ask('What is your Shopify API Secret')
        ctx.system(
          'rails',
          'generate',
          'shopify_app', "--api_key #{api_key}", "--secret #{api_secret}"
        )
        ShopifyCli::Finalize.request_cd(@name)
        puts CLI::UI.fmt(post_clone)
      end

      def post_clone
        "Run {{command:bundle exec rails server}} to start the app server"
      end
    end
  end
end
