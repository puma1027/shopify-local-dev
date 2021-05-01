# frozen_string_literal: true
require "test_helper"
require "shopify-cli/theme/dev_server"

class IntegrationTest < Minitest::Test
  @@port = 9292 # rubocop:disable Style/ClassVars

  THEMES_API_URL = "https://dev-theme-server-store.myshopify.com/admin/api/unstable/themes/123456789.json"
  ASSETS_API_URL = "https://dev-theme-server-store.myshopify.com/admin/api/unstable/themes/123456789/assets.json"

  def setup
    super
    WebMock.disable_net_connect!(allow: "localhost:#{@@port}")

    ShopifyCli::DB.expects(:get)
      .with(:shopify_exchange_token)
      .at_least_once.returns('token123')

    ShopifyCli::DB.expects(:exists?).with(:shop).at_least_once.returns(true)
    ShopifyCli::DB.expects(:get)
      .with(:shop)
      .at_least_once.returns("dev-theme-server-store.myshopify.com")
    ShopifyCli::DB.stubs(:get)
      .with(:development_theme_name)
      .returns("Development theme")
    ShopifyCli::DB.stubs(:get)
      .with(:development_theme_id)
      .returns("123456789")
  end

  def teardown
    if @server_thread
      ShopifyCli::Theme::DevServer.stop
      @server_thread.join
    end
    @@port += 1 # rubocop:disable Style/ClassVars
  end

  def test_proxy_to_sfr
    stub_request(:any, ASSETS_API_URL)
      .to_return(status: 200, body: "{}")
    stub_request(:head, "https://dev-theme-server-store.myshopify.com/?_fd=0&pb=0&preview_theme_id=123456789")
    stub_sfr = stub_request(:get, "https://dev-theme-server-store.myshopify.com/?_fd=0&pb=0")

    start_server
    response = get("/")

    refute_server_errors(response)
    assert_requested(stub_sfr)
  end

  def test_uploads_files_on_boot
    # Get the checksums
    stub_request(:any, ASSETS_API_URL)
      .to_return(status: 200, body: "{}")
    stub_request(:any, THEMES_API_URL)
      .to_return(status: 200, body: "{}")

    start_server
    # Wait for server to start & sync the files
    get("/assets/bogus.css")

    # Should upload all theme files except the ignored files
    ignored_files = [
      "config.yml",
      "super_secret.json",
      "settings_data.json",
      "ignores_file",
    ]
    theme_root = "#{ShopifyCli::ROOT}/test/fixtures/theme"

    Pathname.new(theme_root).glob("**/*").each do |file|
      next unless file.file? && !ignored_files.include?(file.basename.to_s)
      asset = { key: file.relative_path_from(theme_root).to_s }
      if file.extname == ".png"
        asset[:attachment] = Base64.encode64(file.read)
      else
        asset[:value] = file.read
      end

      assert_requested(:put, ASSETS_API_URL,
        body: JSON.generate(asset: asset),
        at_least_times: 1)
    end
  end

  def test_uploads_files_on_modification
    # Get the checksums
    stub_request(:any, ASSETS_API_URL)
      .to_return(status: 200, body: "{}")
    stub_request(:any, THEMES_API_URL)
      .to_return(status: 200, body: "{}")

    start_server
    # Wait for server to start & sync the files
    get("/assets/bogus.css")

    theme_root = "#{ShopifyCli::ROOT}/test/fixtures/theme"

    # Modify a file. Should upload on the fly.
    file = Pathname.new("#{theme_root}/assets/added.css")
    begin
      file.write("added")
      with_retries(Minitest::Assertion) do
        assert_requested(:put, ASSETS_API_URL,
          body: JSON.generate(
            asset: {
              key: "assets/added.css",
              value: "added",
            }
          ),
          at_least_times: 1)
      end
    ensure
      file.delete
    end
  end

  def test_serve_assets_locally
    stub_request(:any, ASSETS_API_URL)
      .to_return(status: 200, body: "{}")
    stub_request(:any, THEMES_API_URL)
      .to_return(status: 200, body: "{}")

    start_server
    response = get("/assets/theme.css")

    refute_server_errors(response)
  end

  def test_streams_hot_reload_events
    stub_request(:any, ASSETS_API_URL)
      .to_return(status: 200, body: "{}")
    stub_request(:any, THEMES_API_URL)
      .to_return(status: 200, body: "{}")

    start_server
    # Wait for server to start
    get("/assets/theme.css")

    # Send the SSE request
    socket = TCPSocket.new("localhost", @@port)
    socket.write("GET /hot-reload HTTP/1.1\r\n")
    socket.write("Host: localhost\r\n")
    socket.write("\r\n")
    socket.flush
    # Read the head
    assert_includes(socket.readpartial(1024), "HTTP/1.1 200 OK")
    # Add a file
    file = Pathname.new("#{ShopifyCli::ROOT}/test/fixtures/theme/assets/theme.css")
    file.write("modified")
    begin
      assert_equal("2a\r\ndata: {\"modified\":[\"assets/theme.css\"]}\n\n\n\r\n", socket.readpartial(1024))
    ensure
      file.write("")
    end
    socket.close
  end

  private

  def start_server
    @ctx = TestHelpers::FakeContext.new(root: "#{ShopifyCli::ROOT}/test/fixtures/theme")
    @server_thread = Thread.new do
      ShopifyCli::Theme::DevServer.start(@ctx, "#{ShopifyCli::ROOT}/test/fixtures/theme", port: @@port)
    rescue Exception => e
      puts "Failed to start DevServer:"
      puts e.message
      puts e.backtrace
    end
  end

  def refute_server_errors(response)
    refute_includes(response, "error", response)
  end

  def get(path)
    with_retries(Errno::ECONNREFUSED) do
      Net::HTTP.get(URI("http://localhost:#{@@port}#{path}"))
    end
  end

  def with_retries(*exceptions, retries: 5)
    yield
  rescue *exceptions
    retries -= 1
    if retries > 0
      sleep(0.1)
      retry
    else
      raise
    end
  end
end
