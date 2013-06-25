module Opencrx
  module Model
    class Record

      def self.have_attributes(*args)
        args.each do |arg|
          define_method(arg) do
            attribute(arg)
          end
          define_method("#{arg}=") do |value|
            write_attribute(arg, value)
          end
        end
      end

      def self.have_array_attributes(*args)
        args.each do |arg|
          define_method(arg) do
            Array.wrap(attribute(arg))
          end
          define_method("#{arg}=") do |value|
            write_attribute(arg, Array.wrap(value))
          end
        end
      end

      class ItemList < Array
        def to_xml(options = nil)
          super(options.merge(children: '_item'))
        end
      end

      attr_accessor :attributes

      def initialize(attributes = {})
        self.attributes = attributes
      end

      def attributes=(hash)
        @attributes = {}
        hash.each do |key, value|
          write_attribute(key, value)
        end
      end

      # store only simple values, or simple arrays.
      # arrays from opencrx are encoded as a hash values under key '_item'
      def write_attribute(key, value)
        key = key.to_s
        case value
          # incoming from opencrx
          when Hash
            items = Array.wrap(value['_item'])
            if items.first.is_a?(String)
              @attributes[key] = ItemList.new(items)
            end
          # incoming from our side
          when Array
            @attributes[key] = ItemList.new(value)
          else
            @attributes[key] = value
        end
        @attributes[key]
      end

      def attribute(key)
        attributes[key.to_s]
      end

      def compact
        attributes.inject({}) do |memo, (key, value)|
          memo[key] = value if value.present? && value != '0'
          memo
        end
      end

      def to_xml(options = {})
        attributes.except('href', 'version').to_xml(options.merge(root: Map.model_to_opencrx_key(self.class)))
      end
    end
  end
end
