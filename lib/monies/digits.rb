# frozen_string_literal: true

module Monies::Digits
  def self.dump(instance, scale: nil, zero: '0', separator: '.', thousands_separator: nil)
    return zero if instance.zero?

    string = instance.value.abs.to_s

    integral_length = string.length - instance.scale

    unless thousands_separator.nil?
      index = integral_length
      while index > 3
        index -= 3
        string.insert(index, thousands_separator)
        integral_length += thousands_separator.length
      end
    end

    unless instance.scale.zero? && scale.nil? || scale == 0
      if integral_length > 0
        string.insert(integral_length, separator)
      else
        string = string.rjust(instance.scale, '0') if integral_length < 0
        string.insert(0, separator)
        string.insert(0, '0')
      end
    end

    unless scale.nil?
      if scale > instance.scale
        string = string.ljust(string.length + scale - instance.scale, '0')
      elsif scale < instance.scale
        string.slice!(scale - instance.scale .. -1)
      end
    end

    string.insert(0, '-') if instance.negative?
    string
  end

  def self.load(string, currency)
    integral_digits, fractional_digits = string.split('.')

    value = integral_digits.to_i

    if fractional_digits.nil?
      scale = 0
    else
      scale = fractional_digits.length

      value *= Monies::BASE ** scale

      if string.start_with?('-')
        value -= fractional_digits.to_i
      else
        value += fractional_digits.to_i
      end
    end

    Monies.new(value, scale, currency)
  end

  REGEXP = /\A\-?\d+(\.\d+)?\z/

  def self.match?(string)
    REGEXP.match?(string)
  end
end
