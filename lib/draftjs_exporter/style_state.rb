# frozen_string_literal: true
module DraftjsExporter
  class StyleState
    INLINE_REGEX = /^(color|bgcolor|fontsize|fontfamily)-/

    INLINE_MAP = {
      color: 'color',
      bgcolor: 'backgroundColor',
      fontsize: 'fontSize',
      fontfamily: 'fontFamily'
    }.freeze

    attr_reader :styles, :style_map

    def initialize(style_map)
      @styles = []
      @style_map = style_map
    end

    def apply(command)
      case command.name
      when :start_inline_style
        styles.push(command.data)
      when :stop_inline_style
        styles.delete(command.data)
      end
    end

    def text?
      styles.empty?
    end

    def element_attributes
      return {} if text?
      { style: styles_css }
    end

    def styles_css
      styles.map { |style|
        inline_style(style) || style_map.fetch(style)
      }.inject({}, :merge).map { |key, value|
        "#{hyphenize(key)}: #{value};"
      }.join
    end

    def inline_style(style)
      return unless INLINE_REGEX =~ style
      key, value = style.split('-')
      raise ArgumentError if value.is_a?(Array)

      {INLINE_MAP.fetch(key.to_sym) => value.gsub(/[^0-9a-z(),]/i, '')}
    end

    def hyphenize(string)
      string.to_s.gsub(/[A-Z]/) { |match| "-#{match.downcase}" }
    end
  end
end
