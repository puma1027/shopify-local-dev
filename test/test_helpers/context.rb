# frozen_string_literal: true
module TestHelpers
  module Context
    include TestHelpers::FakeFS

    def setup
      @context = TestHelpers::FakeContext.new
      @context.root = Dir.mktmpdir
      ::FakeFS::FileSystem.clone(@context.root)
      FileUtils.touch(File.join(@context.root, '.shopify-cli.yml'))
      super
    end

    def teardown
      @context = nil
      super
    end
  end
end
