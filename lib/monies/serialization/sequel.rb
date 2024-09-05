# frozen_string_literal: true

module Monies::Serialization::Sequel
  module ClassMethods
    def serialize_monies(column, currency: nil)
      if currency.is_a?(Symbol) && !columns.include?(currency)
        raise RuntimeError, "missing currency column #{currency.inspect}"
      end

      column_type = db_schema.fetch(column).fetch(:type)

      serialize_monies_attribute(column, column_type, currency)
    end

    def serialize_monies_string(column)
      require 'sequel/plugins/serialization'

      plugin(:serialization) unless respond_to?(:serialization_map)

      serializer, deserializer = Monies.method(:dump), Monies.method(:load)

      define_serialized_attribute_accessor(serializer, deserializer, column)
    end
  end

  module BooleanExpressionPatch
    def to_s_append(dataset, sql)
      column, value = args[0], args[1]

      return super(dataset, sql) unless value.is_a?(Monies)

      column = column.value.to_sym if column.is_a?(::Sequel::SQL::Identifier)

      currency = dataset.model.send(:"#{column}_currency")

      sql << '('
      dataset.literal_append(sql, column)
      sql << ' ' << op.to_s << ' '

      if currency.nil?
        dataset.literal_append(sql, Monies.dump(value))
      elsif currency.is_a?(String)
        unless value.nil? || value.currency == currency
          raise Monies::CurrencyError, "can't serialize #{value.currency} to #{currency}"
        end

        dataset.literal_append(sql, dataset.model.send(:"serialize_#{column}", value))
      elsif currency.is_a?(Symbol)
        dataset.literal_append(sql, dataset.model.send(:"serialize_#{column}", value))
        sql << ' AND '
        dataset.literal_append(sql, currency)
        sql << ' = '
        dataset.literal_append(sql, value.currency)
      end

      sql << ')'
    end
  end

  ::Sequel::SQL::BooleanExpression.class_eval do
    include BooleanExpressionPatch
  end

  def self.apply(model)
    model.extend Monies::Serialization::ClassMethods
  end
end
