# frozen_string_literal: true

module ActiveInteraction
  class Base
    # @!method self.hash(*attributes, options = {}, &block)
    #   Creates accessors for the attributes and ensures that values passed to
    #     the attributes are Hashes.
    #
    #   @!macro filter_method_params
    #   @param block [Proc] filter methods to apply for select keys
    #   @option options [Boolean] :strip (true) remove unknown keys
    #
    #   @example
    #     hash :order
    #   @example
    #     hash :order do
    #       object :item
    #       integer :quantity, default: 1
    #     end
  end

  # @private
  class HashFilter < Filter
    include Missable

    register :hash

    private

    def matches?(value)
      value.is_a?(Hash)
    rescue NoMethodError
      false
    end

    def adjust_output(value, context)
      value = value.with_indifferent_access
      initial = strip? ? ActiveSupport::HashWithIndifferentAccess.new : value

      filters.each_with_object(initial) do |(name, filter), h|
        clean_value(h, name.to_s, filter, value, context)
      end
    end

    def convert(value)
      if value.respond_to?(:to_hash)
        value.to_hash
      else
        value
      end
    rescue NoMethodError
      false
    end

    def clean_value(h, name, filter, value, context)
      h[name] = filter.clean(value[name], context)
    rescue InvalidValueError, MissingValueError
      raise InvalidNestedValueError.new(name, value[name])
    end

    def strip?
      options.fetch(:strip, true)
    end

    def raw_default(*)
      value = super

      if value.is_a?(Hash) && !value.empty?
        raise InvalidDefaultError, "#{name}: #{value.inspect}"
      end

      value
    end

    def method_missing(*args, &block) # rubocop:disable Style/MethodMissing
      super(*args) do |klass, names, options|
        validate!(names, options)

        names.each do |name|
          filters[name] = klass.new(name, options, &block)
        end
      end
    end

    def validate!(names, options)
      raise InvalidFilterError, 'missing attribute name' if names.empty?
      if options.key?(:groups)
        raise InvalidFilterError, 'nested filters can not be a part of a group'
      end

      nil
    end
  end
end
