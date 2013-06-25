module Opencrx
  module Model
    module Result
      class << self
        def parse(result)
          raise "Expected a single key, got [#{result.keys}]" unless result.keys.length == 1
          if result.has_key?('org.openmdx.kernel.Exception')
            Opencrx.logger.warn { result.body }
            return nil
          end
          key = result.keys.first
          if (klass = Map.opencrx_key_to_model(key))
            klass.new(result[key])
          else
            raise "Could not convert [#{key}] to a model class"
          end
        end
      end
    end
  end
end