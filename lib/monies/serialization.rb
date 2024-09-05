module Monies::Serialization
  autoload :ActiveRecord, 'monies/serialization/active_record'
  autoload :Sequel, 'monies/serialization/sequel'

  module ClassMethods
    def serialize_monies_attribute(column, column_type, currency)
      singleton_class.define_method(:"#{column}_currency") { currency }

      if currency.nil?
        unless column_type == :string
          raise ArgumentError, "can't serialize monies to #{column_type} column without currency"
        end

        return serialize_monies_string(column)
      elsif currency.is_a?(Symbol)
        if column_type == :string
          define_method(:"deserialize_#{column}") { |value| Monies::Digits.load(value, self[currency]) }
        else
          define_method(:"deserialize_#{column}") { |value| Monies(value, self[currency]) }
        end

        define_method(:"#{column}=") do |value|
          result = super(value.nil? ? nil : self.class.send(:"serialize_#{column}", value))
          send(:"#{currency}=", value&.currency)
          result
        end
      elsif currency.is_a?(String)
        if column_type == :string
          define_method(:"deserialize_#{column}") { |value| Monies::Digits.load(value, currency) }
        else
          define_method(:"deserialize_#{column}") { |value| Monies(value, currency) }
        end

        define_method(:"#{column}=") do |value|
          unless value.nil? || value.currency == currency
            raise Monies::CurrencyError, "can't serialize #{value.currency} to #{currency}"
          end

          super(value.nil? ? nil : self.class.send(:"serialize_#{column}", value))
        end
      else
        raise ArgumentError, "can't serialize monies with #{currency.class} currency"
      end

      if column_type == :string
        singleton_class.define_method(:"serialize_#{column}") { |value| Monies::Digits.dump(value) }
      else
        singleton_class.define_method(:"serialize_#{column}") { |value| value.to_d }
      end

      define_method(column) do
        value = super()

        send(:"deserialize_#{column}", value) unless value.nil?
      end
    end
  end
end
