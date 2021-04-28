# frozen_string_literal: true
require "thread"
require "json"
require "base64"

module ShopifyCli
  module Theme
    class Uploader
      class Operation < Struct.new(:method, :file)
        def to_s
          "#{method} #{file&.relative_path}"
        end
      end
      API_VERSION = "unstable"

      attr_reader :checksums

      def initialize(ctx, theme)
        @ctx = ctx
        @theme = theme

        # Queue of `Operation`s waiting to be picked up from a thread for processing.
        @queue = Queue.new
        # `Operation`s will be removed from this Array completed.
        @pending = []
        # Thread making the API requests.
        @threads = []
        # Mutex used to pause all threads when backing-off when hitting API rate limits
        @backoff_mutex = Mutex.new

        # Allows delaying log of errors, mainly to not break the progress bar.
        @delay_errors = false
        @delayed_errors = []

        # Latest theme assets checksums. Updated on each upload.
        @checksums = {}
      end

      def enqueue_updates(files)
        files.each { |file| enqueue(:update, file) }
      end

      def enqueue_deletes(files)
        files.each { |file| enqueue(:delete, file) }
      end

      def size
        @pending.size
      end

      def empty?
        @pending.empty?
      end

      def pending_updates
        @pending.select { |op| op.method == :update }.map(&:file)
      end

      def remote_file?(file)
        checksums.key?(@theme[file].relative_path.to_s)
      end

      def wait!
        raise ThreadError, "No uploader threads" if @threads.empty?
        total = size
        last_size = size
        until empty? || @queue.closed?
          if block_given? && last_size != size
            yield size, total
            last_size = size
          end
          Thread.pass
        end
      end

      def fetch_checksums!
        _status, response = ShopifyCli::AdminAPI.rest_request(
          @ctx,
          shop: @theme.shop,
          path: "themes/#{@theme.id}/assets.json",
          api_version: API_VERSION,
        )
        update_checksums(response)
      end

      def shutdown
        @queue.close unless @queue.closed?
      ensure
        @threads.each { |thread| thread.join if thread.alive? }
      end

      def start_threads(count = 2)
        count.times do
          @threads << Thread.new do
            loop do
              operation = @queue.pop
              break if operation.nil? # shutdown was called
              perform(operation)
            rescue => e
              report_error(
                "{{red:ERROR}} {{blue:#{operation}}}: #{e}" +
                (@ctx.debug? ? "\n\t#{e.backtrace.join("\n\t")}" : "")
              )
            end
          end
        end
      end

      def delay_errors!
        @delay_errors = true
      end

      def report_errors!
        @delay_errors = false
        @delayed_errors.each { |error| report_error(error) }
        @delayed_errors.clear
      end

      def upload_theme!(delay_low_priority_files: false, delete: true, &block)
        fetch_checksums!

        if delete
          # Delete remote files not present locally
          removed_files = checksums.keys - @theme.theme_files.map { |file| file.relative_path.to_s }
          enqueue_deletes(removed_files)
        end

        # Some files must be uploaded after the other ones
        delayed_config_files = [
          @theme["config/settings_schema.json"],
          @theme["config/settings_data.json"],
        ]

        enqueue_updates(@theme.liquid_files)
        enqueue_updates(@theme.json_files - delayed_config_files)
        enqueue_updates(delayed_config_files)

        if delay_low_priority_files
          # Wait for liquid & JSON files to upload, because those are rendered remotely
          wait!(&block)
        end

        # Process lower-priority files in the background

        # Assets are served locally, so can be uploaded in the background
        enqueue_updates(@theme.asset_files)

        unless delay_low_priority_files
          wait!(&block)
        end
      end

      def upload_theme_with_progress_bar!(**args)
        delay_errors!
        CLI::UI::Progress.progress do |bar|
          upload_theme!(**args) do |left, total|
            bar.tick(set_percent: 1 - left.to_f / total)
          end
          bar.tick(set_percent: 1)
        end
        report_errors!
      end

      private

      def enqueue(method, file)
        operation = Operation.new(method, @theme[file])

        # Already enqueued
        return if @pending.include?(operation)

        if @theme.ignore?(operation.file)
          @ctx.debug("ignore #{operation.file.relative_path}")
          return
        end

        if method == :update && operation.file.exist? && !file_has_changed?(operation.file)
          @ctx.debug("skip #{operation}")
          return
        end

        @pending << operation
        @queue << operation unless @queue.closed?
      end

      def perform(operation)
        return if @queue.closed?
        wait_for_backoff!
        @ctx.debug(operation.to_s)

        response = send(operation.method, operation.file)

        # Check if the API told us we're near the rate limit
        if !backingoff? && (limit = response["x-shopify-shop-api-call-limit"])
          used, total = limit.split("/").map(&:to_i)
          backoff_if_near_limit!(used, total)
        end
      rescue ShopifyCli::API::APIRequestError => e
        report_error(
          "{{red:ERROR}} {{blue:#{operation}}}:\n  " +
          parse_api_errors(e).join("\n  ")
        )
      ensure
        @pending.delete(operation)
      end

      def update(file)
        asset = { key: file.relative_path.to_s }
        if file.text?
          asset[:value] = file.read
        else
          asset[:attachment] = Base64.encode64(file.read)
        end

        _status, body, response = ShopifyCli::AdminAPI.rest_request(
          @ctx,
          shop: @theme.shop,
          path: "themes/#{@theme.id}/assets.json",
          method: "PUT",
          api_version: API_VERSION,
          body: JSON.generate(asset: asset)
        )

        update_checksums(body)

        response
      end

      def delete(file)
        _status, _body, response = ShopifyCli::AdminAPI.rest_request(
          @ctx,
          shop: @theme.shop,
          path: "themes/#{@theme.id}/assets.json",
          method: "DELETE",
          api_version: API_VERSION,
          body: JSON.generate(asset: {
            key: file.relative_path.to_s
          })
        )

        response
      end

      def update_checksums(api_response)
        api_response.values.flatten.each do |asset|
          @checksums[asset["key"]] = asset["checksum"]
        end
        # Generate .liquid asset files are reported twice in checksum:
        # once of generated, once for .liquid. We only keep the .liquid, that's the one we have
        # on disk.
        @checksums.reject! { |key, _| @checksums.key?("#{key}.liquid") }
      end

      def file_has_changed?(file)
        file.checksum != @checksums[file.relative_path.to_s]
      end

      def report_error(error)
        if @delay_errors
          @delayed_errors << error
        else
          @ctx.puts(error)
        end
      end

      def parse_api_errors(exception)
        parsed_body = JSON.parse(exception&.response&.body)
        message = parsed_body.dig("errors", "asset") || parsed_body["message"] || exception.message
        # Truncate to first lines
        [message].flatten.map { |message| message.split("\n", 2).first }
      rescue JSON::ParserError
        [exception.message]
      end

      def backoff_if_near_limit!(used, limit)
        if used > limit - @threads.size
          @ctx.debug("Near API call limit, waiting 2 sec ...")
          @backoff_mutex.synchronize { sleep 2 }
        end
      end

      def backingoff?
        @backoff_mutex.locked?
      end

      def wait_for_backoff!
        # Sleeping in the mutex in another thread. Wait for unlock
        @backoff_mutex.synchronize {} if backingoff?
      end
    end
  end
end
