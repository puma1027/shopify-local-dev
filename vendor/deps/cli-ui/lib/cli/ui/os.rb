module CLI
  module UI
    module OS
      # Determines which OS is currently running the UI, to make it easier to
      # adapt its behaviour to the features of the OS.
      def self.current
        @current_os ||= case RUBY_PLATFORM
        when /darwin/
          Mac
        when /linux/
          Linux
        when /mingw32/
          Windows
        else
          Mac
          #raise "Could not determine OS from platform #{RUBY_PLATFORM}"
        end
      end

      class Mac
        class << self
          def supports_emoji?
            true
          end

          def supports_color_prompt?
            true
          end

          def supports_arrow_keys?
            true
          end

          def shift_cursor_on_line_reset?
            false
          end
        end
      end

      class Linux < Mac
      end

      class Windows
        class << self
          def supports_emoji?
            false
          end

          def supports_color_prompt?
            false
          end

          def supports_arrow_keys?
            false
          end

          def shift_cursor_on_line_reset?
            true
          end
        end
      end
    end
  end
end
