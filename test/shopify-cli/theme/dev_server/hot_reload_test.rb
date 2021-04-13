# frozen_string_literal: true
require "test_helper"
require "shopify-cli/theme/dev_server"
require "rack/mock"

module ShopifyCli
  module Theme
    module DevServer
      class HotReloadTest < Minitest::Test
        def setup
          super
          config = Config.from_path(ShopifyCli::ROOT + "/test/fixtures/theme")
          @ctx = TestHelpers::FakeContext.new(root: config.root)
          @theme = Theme.new(@ctx, config)
          @uploader = stub("Uploader", enqueue_uploads: true)
          @watcher = Watcher.new(@ctx, @theme, @uploader)
        end

        def test_hot_reload_js_injected_if_html_request
          html = <<~HTML
            <html>
              <head></head>
              <body>
                <h1>Hello</h1>
              </body>
            </html>
          HTML

          reload_js = File.read(File.expand_path("lib/shopify-cli/theme/dev_server/hot-reload.js", ShopifyCli::ROOT))
          reload_script = "<script>\n#{reload_js}</script>"
          expected_html = <<~HTML
            <html>
              <head></head>
              <body>
                <h1>Hello</h1>
              #{reload_script}
            </body>
            </html>
          HTML

          response = serve(html, headers: { "content-type" => "text/html" })

          assert_equal(expected_html, response)
        end

        def test_does_not_inject_hot_reload_js_for_non_html_responses
          css = <<~CSS
            .body { color: red }
          CSS

          response = serve(css, headers: { "content-type" => "text/css" })

          assert_equal(css, response)
        end

        def test_streams_on_hot_reload_path
          SSE::Stream.any_instance.expects(:each).yields("")
          serve(path: "/hot-reload")
        end

        def test_broadcasts_watcher_events
          modified = ["style.css"]
          SSE::Streams.any_instance
            .expects(:broadcast)
            .with(JSON.generate(modified: modified))

          app = -> { [200, {}, []] }
          HotReload.new(@ctx, app, @theme, @watcher)

          @watcher.changed
          @watcher.notify_observers(modified, [], [])
        end

        private

        def serve(response_body = "", path: "/", headers: {})
          app = lambda do |_env|
            [200, headers, [response_body]]
          end
          stack = HotReload.new(@ctx, app, @theme, @watcher)
          request = Rack::MockRequest.new(stack)
          request.get(path).body
        end
      end
    end
  end
end
