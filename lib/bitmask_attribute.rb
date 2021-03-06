require 'bitmask_attribute/value_proxy'

module BitmaskAttribute
  
  class Definition
    
    attr_reader :attribute, :values, :extension
    def initialize(attribute, values=[], &extension)
      @attribute = attribute
      @values = values
      @extension = extension
    end
    
    def install_on(model)
      validate_for model
      generate_bitmasks_on model
      override model
      create_convenience_method_on model
    end
    
    #######
    private
    #######

    def validate_for(model)
      unless model.columns.detect { |col| col.name == attribute.to_s && col.type == :integer }
        raise ArgumentError, "`#{attribute}' is not an integer column of `#{model}'"
      end
    end
    
    def generate_bitmasks_on(model)
      model.bitmasks[attribute] = returning HashWithIndifferentAccess.new do |mapping|
        values.each_with_index do |value, index|
          mapping[value] = 0b1 << index
        end
      end
    end
    
    def override(model)
      override_getter_on(model)
      override_setter_on(model)
    end
    
    def override_getter_on(model)
      model.class_eval %(
        def #{attribute}
          @#{attribute} ||= BitmaskAttribute::ValueProxy.new(self, :#{attribute}, &self.class.bitmask_definitions[:#{attribute}].extension)
        end
      )
    end
    
    def override_setter_on(model)
      model.class_eval %(
        def #{attribute}=(raw_value)
          values = raw_value.kind_of?(Array) ? raw_value : [raw_value]
          self.#{attribute}.replace(values.reject(&:blank?))
        end
      )
    end
    
    def create_convenience_method_on(model)
      model.class_eval %(
        def self.bitmask_for_#{attribute}(*values)
          values.inject(0) do |bitmask, value|
            unless (bit = bitmasks[:#{attribute}][value])
              raise ArgumentError, "Unsupported value for #{attribute}: \#{value.inspect}"
            end
            bitmask | bit
          end
        end
      )
    end
    
  end
  
  def self.included(model)
    model.extend ClassMethods
  end
    
  module ClassMethods
    
    def bitmask(attribute, options={}, &extension)
      unless options[:as] && options[:as].kind_of?(Array)
        raise ArgumentError, "Must provide an Array :as option"
      end
      bitmask_definitions[attribute] = BitmaskAttribute::Definition.new(attribute, options[:as].to_a, &extension)
      bitmask_definitions[attribute].install_on(self)
    end
    
    def bitmask_definitions
      @bitmask_definitions ||= {}
    end
    
    def bitmasks
      @bitmasks ||= {}
    end
      
  end
  
end