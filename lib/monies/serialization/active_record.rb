# frozen_string_literal: true

module Monies::Serialization::ActiveRecord
  module ClassMethods
    def serialize_monies(column, currency: nil)
      if currency.is_a?(Symbol) && !column_names.include?(currency.to_s)
        raise RuntimeError, "missing currency column #{currency.inspect}"
      end

      column_type = columns.find { _1.name == column.to_s }.sql_type_metadata.type

      serialize_monies_attribute(column, column_type, currency)
    end

    def serialize_monies_string(column)
      serialize(column, coder: Monies)
    end

    def predicate_builder
      @predicate_builder ||= super().tap { _1.register_handler(Monies, PredicateBuilderHandler.new(_1, self)) }
    end
  end

  class PredicateBuilderHandler
    def initialize(predicate_builder, model)
      @predicate_builder, @model = predicate_builder, model
    end

    def call(attribute, value)
      currency = @model.send(:"#{attribute.name}_currency")

      if currency.nil?
        @predicate_builder.build(attribute, Monies.dump(value))
      elsif currency.is_a?(String)
        unless value.nil? || value.currency == currency
          raise Monies::CurrencyError, "can't serialize #{value.currency} to #{currency}"
        end

        @predicate_builder.build(attribute, @model.send(:"serialize_#{attribute.name}", value))
      elsif currency.is_a?(Symbol)
        Arel::Nodes::And.new([
          @predicate_builder.build(attribute, @model.send(:"serialize_#{attribute.name}", value)),
          @predicate_builder[currency, value.currency]
        ])
      end
    end
  end

  def self.included(model)
    model.extend Monies::Serialization::ClassMethods
    model.extend ClassMethods
  end
end
