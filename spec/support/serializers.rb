require 'spec_helper'

# TODO: Add better instrumentation
class UserSerializer
  class << self
    def with_overrides(array = [])
      undefine_all
      case array
      when Array
        array.each do |meth|
          send(:define_method, meth) do
            if object.send(meth).respond_to?('*')
              object.send(meth) * 2
            else
              'Something else'
            end
          end
        end
      when Hash
        array.each do |meth, value|
          send(:define_method, meth) do
            value
          end
        end
      else
        raise 'wrong type'
      end
    end

    def undefine_all
      model_klass = Object.const_get(to_s.gsub('Serializer', ''))
      model_klass.model_attributes.each do |meth|
        begin
          send(:remove_method, meth)
        rescue NameError => _e
        end
      end
    end
  end
  include SimpleAMS::DSL
end
class MicropostSerializer < UserSerializer; end
class AddressSerializer < UserSerializer; end

# rubocop:disable Style/ClassAndModuleChildren
class Api
  class V1
    class UserSerializer < UserSerializer
    end

    class MicropostSerializer < MicropostSerializer
    end

    class AddressSerializer < AddressSerializer
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
