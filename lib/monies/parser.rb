# frozen_string_literal: true
require 'strscan'

class Monies::Parser < StringScanner
  def parse
    if comma_decimal_separator?
      @decimal_separator = COMMA

      @thousands_separator = POINT_THINSP
    else
      @decimal_separator = POINT

      @thousands_separator = COMMA
    end

    parse_minus_sign
    parse_currency_symbol
    parse_integral_digits
    parse_fractional_digits
    parse_space
    parse_currency_code

    if @integral_digits.nil?
      raise ArgumentError, "can't parse #{string.inspect}"
    end

    if @fractional_digits.nil?
      value = @integral_digits.to_i

      scale = 0
    else
      value = (@integral_digits + @fractional_digits).to_i

      scale = @fractional_digits.length
    end

    currency = if @currency_code
      @currency_code
    elsif @currency_symbol
      Monies.symbols.fetch(@currency_symbol)
    elsif Monies.currency
      Monies.currency
    else
      raise ArgumentError, "can't parse #{string.inspect} without currency"
    end

    if @minus_sign
      -Monies.new(value, scale, currency)
    else
      Monies.new(value, scale, currency)
    end
  end

  private

  DIGITS = /\d+/

  POINT = /\./

  COMMA = /,/

  COMMA_TWO_DIGITS = /,\d{2}\b/

  POINT_THINSP = /[\.\u{2009}]/

  MINUS = /-/

  SPACE = /\s/

  def comma_decimal_separator?
    return true if string =~ COMMA_TWO_DIGITS

    point_index = string =~ POINT

    comma_index = string =~ COMMA

    comma_index && point_index && comma_index > point_index
  end

  def parse_minus_sign
    @minus_sign = scan(MINUS)
  end

  def parse_currency_symbol
    @currency_symbol = scan(Monies.symbols.keys)
  end

  def parse_integral_digits
    parse_minus_sign if @minus_sign.nil?

    @integral_digits = scan(DIGITS)

    while scan(@thousands_separator)
      @integral_digits += scan(DIGITS)
    end
  end

  def parse_fractional_digits
    @fractional_digits = scan(@decimal_separator) && scan(DIGITS)
  end

  def parse_space
    scan(SPACE)
  end

  def parse_currency_code
    @currency_code = scan(Monies.symbols.values)
  end
end
