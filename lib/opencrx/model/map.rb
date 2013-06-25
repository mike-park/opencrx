require 'active_support/inflector'

module Opencrx
  module Model
    module Map
      class << self
        def opencrx_key_to_model(key)
          unless key.match(/^#{BASE_KEY}\.(.*)$/)
            raise "Unexpected key #{key}"
          end
          target_class_name = $1
          ActiveSupport::Inflector.safe_constantize("::Opencrx::Model::#{target_class_name}")
        end

        def model_to_opencrx_key(klass)
          "#{BASE_KEY}.#{demodulized_class_name(klass)}"
        end

        def model_to_opencrx_query(klass)
          model_to_opencrx_key(klass).gsub(/\./, ':')
        end

        private

        def demodulized_class_name(klass)
          ActiveSupport::Inflector.demodulize klass
        end
      end
    end
  end
end