# frozen_string_literal: true
require "test_helper"
require "shopify-cli/theme/dev_server"

class SSETest < Minitest::Test
  def test_broadcast_events
    streams = ShopifyCli::Theme::DevServer::SSE::Streams.new
    stream = streams.new

    events = []
    thread = Thread.new do
      stream.each do |event|
        events << event
      end
    end

    streams.broadcast("SOME-DATA")
    streams.broadcast("SOME-MORE-DATA")
    stream.close

    thread.join

    assert_equal([
      "data: SOME-DATA\n\n\n",
      "data: SOME-MORE-DATA\n\n\n",
    ], events)
  end
end
