# coding: utf-8
require 'test_helper'

module CLI
  module UI
    class FormatterTest < MiniTest::Test
      def test_format
        input = "a{{blue:b {{*}}{{bold:c {{red:d}}}}{{bold: e}}}} f"
        expected = "\e[0ma\e[0;94mb \e[0;33m⭑\e[0;94;1mc \e[0;94;1;31md\e[0;94;1m e\e[0m f"
        actual = CLI::UI::Formatter.new(input).format
        assert_equal(expected, actual)
      end

      def test_format_no_color
        input = "a{{blue:b {{*}}{{bold:c {{red:d}}}}{{bold: e}}}} f {{bold:}}"
        expected = "ab ⭑c d e f "
        actual = CLI::UI::Formatter.new(input).format(enable_color: false)
        assert_equal(expected, actual)
      end

      def test_format_trailing
        input = "a{{bold:a {{blue:"
        ex = assert_raises(CLI::UI::Formatter::FormatError) do
          CLI::UI::Formatter.new(input).format
        end
        expected = 'Mismatched braces in input'
        assert_equal(input, ex.input)
        assert_equal(-1, ex.index)
        assert_equal(expected, ex.message)
      end

      def test_out_of_order_braces
        input = '}}{{blue:foo'
        ex = assert_raises(CLI::UI::Formatter::FormatError) do
          CLI::UI::Formatter.new(input).format
        end
        expected = 'Mismatched braces in input'
        assert_equal(input, ex.input)
        assert_equal(-1, ex.index)
        assert_equal(expected, ex.message)
      end

      def test_leading_literal_closing_braces
        input = '}} foo'
        expected = "\e[0m}} foo"
        actual = CLI::UI::Formatter.new(input).format
        assert_equal(expected, actual)
      end

      def test_trailing_literal_closing_braces
        input = 'foo}}'
        expected = "\e[0mfoo}}"
        actual = CLI::UI::Formatter.new(input).format
        assert_equal(expected, actual)
      end

      def test_extra_closing_braces
        input = '{{blue:foo}}}}'
        expected = "\e[0;94mfoo\e[0m}}"
        actual = CLI::UI::Formatter.new(input).format
        assert_equal(expected, actual)
      end

      def test_invalid_funcname
        input = "{{nope:text}}"
        ex = assert_raises(CLI::UI::Formatter::FormatError) do
          CLI::UI::Formatter.new(input).format
        end
        expected = "invalid format specifier: nope"
        assert_equal(input, ex.input)
        assert_equal(-1, ex.index)
        assert_equal(expected, ex.message)
      end

      def test_invalid_glyph
        input = "{{&}}"
        ex = assert_raises(CLI::UI::Formatter::FormatError) do
          CLI::UI::Formatter.new(input).format
        end
        expected = "invalid glyph handle at index 3: '&'"
        assert_equal(input, ex.input)
        assert_equal(3, ex.index)
        assert_equal(expected, ex.message)
      end

      def test_mixed_non_syntax
        input = "{{bold:{{foo {{green:bar}} }}}}"
        expected = "\e[0;1m{{foo \e[0;1;32mbar\e[0;1m }}\e[0m"
        actual = CLI::UI::Formatter.new(input).format
        assert_equal(expected, actual)
      end

      def test_incomplete_non_syntax
        input = "{{foo"
        expected = "\e[0m{{foo"
        actual = CLI::UI::Formatter.new(input).format
        assert_equal(expected, actual)
      end

      def test_reset_after_glyph
        input = "{{*}} foobar"
        expected = "\e[0;33m⭑\e[0m foobar"

        actual = CLI::UI::Formatter.new(input).format
        assert_equal(expected, actual)
      end
    end
  end
end
