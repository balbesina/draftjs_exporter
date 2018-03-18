module DraftjsExporter
  module Entities
    class Image
      attr_reader :configuration

      def initialize(configuration = { className: nil })
        @configuration = configuration
      end

      def call(parent_element, data)
        args = {}
        args[:class] = configuration[:className]

        img_attributes = data.fetch(:data, {})
        align = img_attributes.delete('alignment')
        align = 'center' unless %w[left right].include?(align)
        parent_style = parent_element[:style] ||= ''
        parent_element[:style] = "text-align: #{align};#{parent_style}"

        args.merge!(img_attributes)

        element = parent_element.document.create_element('img', args.compact)
        parent_element.add_child(element)
        element
      end
    end
  end
end
