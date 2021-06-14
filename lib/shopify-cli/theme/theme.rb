# frozen_string_literal: true
require_relative "file"
require_relative "config"
require_relative "ignore_filter"

require "time"

module ShopifyCli
  module Theme
    class Theme
      attr_reader :config, :id

      def initialize(ctx, config = nil, id: nil, name: nil, role: nil)
        @ctx = ctx
        @config = config || Config.new
        @id = id
        @name = name
        @role = role
        @ignore_filter = IgnoreFilter.new(root, patterns: @config.ignore_files, files: @config.ignores)
      end

      def root
        @config.root
      end

      def theme_files
        glob(["**/*.liquid", "**/*.json", "assets/*"])
      end

      def asset_files
        glob("assets/*")
      end

      def liquid_files
        glob("**/*.liquid")
      end

      def json_files
        glob("**/*.json")
      end

      def glob(pattern)
        root.glob(pattern).map { |path| File.new(path, root) }
      end

      def theme_file?(file)
        theme_files.include?(self[file])
      end

      def asset_paths
        asset_files.map(&:relative_path)
      end

      def [](file)
        case file
        when File
          file
        when Pathname
          File.new(file, root)
        when String
          File.new(root.join(file), root)
        end
      end

      def shop
        AdminAPI.get_shop(@ctx)
      end

      def ignore?(file)
        @ignore_filter.match?(self[file].path.to_s)
      end

      def editor_url
        "https://#{shop}/admin/themes/#{id}/editor"
      end

      def name
        return @name if @name
        load_info_from_api.name
      end

      def role
        if @role == "main"
          # Main theme is called Live in UI
          "live"
        elsif @role
          @role
        else
          load_info_from_api.role
        end
      end

      def live?
        role == "live"
      end

      def preview_url
        if live?
          "https://#{shop}/"
        else
          "https://#{shop}/?preview_theme_id=#{id}"
        end
      end

      def delete
        AdminAPI.rest_request(
          @ctx,
          shop: shop,
          method: "DELETE",
          path: "themes/#{id}.json",
          api_version: "unstable",
        )
      end

      def publish
        return if live?
        AdminAPI.rest_request(
          @ctx,
          shop: shop,
          method: "PUT",
          path: "themes/#{id}.json",
          api_version: "unstable",
          body: JSON.generate(theme: {
            role: "main",
          })
        )
        @role = "live"
      end

      def to_h
        {
          id: id,
          name: name,
          role: role,
          shop: shop,
          editor_url: editor_url,
          preview_url: preview_url,
        }
      end

      def self.all(ctx, config)
        _status, body = AdminAPI.rest_request(
          ctx,
          shop: AdminAPI.get_shop(ctx),
          path: "themes.json",
          api_version: "unstable",
        )

        body["themes"]
          .sort_by { |attributes| Time.parse(attributes["updated_at"]) }
          .reverse
          .map do |attributes|
            new(
              ctx, config,
              id: attributes["id"],
              name: attributes["name"],
              role: attributes["role"],
            )
          end
      end

      private

      def load_info_from_api
        _status, body = AdminAPI.rest_request(
          @ctx,
          shop: shop,
          path: "themes/#{id}.json",
          api_version: "unstable",
        )

        @name = body.dig("theme", "name")
        @role = body.dig("theme", "role")

        self
      end
    end
  end
end
