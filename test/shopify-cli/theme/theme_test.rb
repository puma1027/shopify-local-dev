# frozen_string_literal: true
require "test_helper"
require "shopify-cli/theme/config"
require "shopify-cli/theme/theme"

module ShopifyCli
  module Theme
    class ThemeTest < Minitest::Test
      def setup
        super
        config = Config.from_path(ShopifyCli::ROOT + "/test/fixtures/theme")
        @ctx = TestHelpers::FakeContext.new(root: config.root)
        @theme = Theme.new(@ctx, config)
      end

      def test_assets
        assert_includes(@theme.asset_paths, Pathname.new("assets/theme.css"))
      end

      def test_theme_files
        assert_includes(@theme.theme_files.map(&:relative_path), Pathname.new("layout/theme.liquid"))
        assert_includes(@theme.theme_files.map(&:relative_path), Pathname.new("templates/blog.json"))
        assert_includes(@theme.theme_files.map(&:relative_path), Pathname.new("locales/en.default.json"))
        assert_includes(@theme.theme_files.map(&:relative_path), Pathname.new("assets/theme.css"))
        assert_includes(@theme.theme_files.map(&:relative_path), Pathname.new("assets/theme.js"))
      end

      def test_get_file
        assert_equal(Pathname.new("layout/theme.liquid"), @theme["layout/theme.liquid"].relative_path)
        assert_equal(Pathname.new("layout/theme.liquid"),
          @theme[Pathname.new("#{ShopifyCli::ROOT}/test/fixtures//theme/layout/theme.liquid")].relative_path)
        assert_equal(@theme.theme_files.first, @theme[@theme.theme_files.first])
      end

      def test_theme_file
        assert(@theme["layout/theme.liquid"].liquid?)
        refute(@theme["layout/theme.liquid"].json?)
        assert(@theme["templates/blog.json"].json?)
        assert(@theme["templates/blog.json"].template?)
        assert(@theme["locales/en.default.json"].json?)
        refute(@theme["locales/en.default.json"].template?)
      end

      def test_is_theme_file
        assert(@theme.theme_file?(@theme["layout/theme.liquid"]))
        assert(@theme.theme_file?(
          @theme[Pathname.new(ShopifyCli::ROOT).join("test/fixtures/theme/layout/theme.liquid")]
        ))
      end

      def test_ignores_file
        assert(@theme.ignore?(@theme["config/settings_data.json"]))
        assert(@theme.ignore?(@theme["config/super_secret.json"]))
        refute(@theme.ignore?(@theme["assets/theme.css"]))
      end

      def test_creates_development_theme_if_missing_from_storage
        shop = "dev-theme-server-store.myshopify.com"
        theme_name = "Development (5676d8-theme-dev)"

        ShopifyCli::AdminAPI.stubs(:get_shop).returns(shop)
        ShopifyCli::DB.stubs(:get).with(:development_theme_id).returns(nil)
        ShopifyCli::DB.expects(:set).with(development_theme_id: "12345678")
        @theme.stubs(:name).returns(theme_name)

        ShopifyCli::AdminAPI.expects(:rest_request).with(
          @ctx,
          shop: shop,
          path: "themes.json",
          method: "POST",
          body: JSON.generate({
            theme: {
              name: theme_name,
              role: "development",
            },
          }),
          api_version: "unstable",
        ).returns([
          201,
          "theme" => {
            "id" => "12345678",
          },
        ])

        @theme.ensure_development_theme_exists!
      end

      def test_creates_development_theme_if_missing_from_api
        shop = "dev-theme-server-store.myshopify.com"
        theme_name = "Development (5676d8-theme-dev)"
        theme_id = "12345678"

        ShopifyCli::AdminAPI.stubs(:get_shop).returns(shop)
        ShopifyCli::DB.stubs(:get).with(:development_theme_id).returns(theme_id)
        ShopifyCli::DB.expects(:set).with(development_theme_id: "12345678")
        @theme.stubs(:name).returns(theme_name)

        ShopifyCli::AdminAPI.expects(:rest_request).with(
          @ctx,
          shop: shop,
          path: "themes/#{theme_id}.json",
          api_version: "unstable",
        ).raises(ShopifyCli::API::APIRequestNotFoundError)

        ShopifyCli::AdminAPI.expects(:rest_request).with(
          @ctx,
          shop: shop,
          path: "themes.json",
          method: "POST",
          body: JSON.generate({
            theme: {
              name: theme_name,
              role: "development",
            },
          }),
          api_version: "unstable",
        ).returns([
          201,
          "theme" => {
            "id" => "12345678",
          },
        ])

        @theme.ensure_development_theme_exists!
      end

      def test_name_is_generated_unless_exists_in_db
        hostname = "theme-dev.lan"
        hash = "5676d"
        theme_name = "Development (#{hash}-#{hostname.split(".").shift})"

        ShopifyCli::DB.stubs(:get).with(:development_theme_name).returns(nil)
        SecureRandom.expects(:hex).returns(hash)
        Socket.expects(:gethostname).returns(hostname)
        ShopifyCli::DB.expects(:set).with(development_theme_name: theme_name)

        assert_equal(theme_name, @theme.name)
      end

      def test_mime_type
        assert_equal("text/x-liquid", @theme["layout/theme.liquid"].mime_type.name)
        assert_equal("text/css", @theme["assets/theme.css"].mime_type.name)
      end

      def test_text
        assert(@theme["layout/theme.liquid"].mime_type.text?)
      end

      def test_checksum
        content = @theme["layout/theme.liquid"].read
        assert_equal(Digest::MD5.hexdigest(content), @theme["layout/theme.liquid"].checksum)
      end

      def test_normalize_json_for_checksum
        normalized = JSON.parse(@theme["templates/blog.json"].read).to_json
        assert_equal(Digest::MD5.hexdigest(normalized), @theme["templates/blog.json"].checksum)
      end

      def test_update_remote_checksum
        @theme.update_remote_checksums!(
          "asset" => [
            {
              "key" => "templates/product.json",
              "checksum" => "16f0c357cd150aac7758c144a3ff576f",
            },
            {
              "key" => "templates/search.liquid",
              "checksum" => "8a90fadd03f8ef7f08511b5509cada4d",
            },
          ]
        )

        @theme.update_remote_checksums!(
          "asset" => {
            "key" => "config/settings_schema.json",
            "checksum" => "a785758d09023273fda4bb57bd42a724",
          }
        )

        assert_equal("16f0c357cd150aac7758c144a3ff576f", @theme.remote_checksums["templates/product.json"])
        assert_equal("8a90fadd03f8ef7f08511b5509cada4d", @theme.remote_checksums["templates/search.liquid"])
        assert_equal("a785758d09023273fda4bb57bd42a724", @theme.remote_checksums["config/settings_schema.json"])
      end
    end
  end
end
