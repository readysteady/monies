# frozen_string_literal: true

class Monies
  BASE = 10

  CurrencyError = Class.new(ArgumentError)

  autoload :Digits, 'monies/digits'
  autoload :Format, 'monies/format'
  autoload :Parser, 'monies/parser'
  autoload :Serialization, 'monies/serialization'
  autoload :Symbols, 'monies/symbols'

  class << self
    attr_accessor :currency
    attr_accessor :formats
    attr_accessor :symbols
  end

  self.currency = nil

  self.formats = {
    default: Monies::Format::EN.new,
    en: Monies::Format::EN.new,
    eu: Monies::Format::EU.new,
  }

  self.symbols = Symbols.new.update({
    '$' => 'USD',
    '€' => 'EUR',
    '¥' => 'JPY',
    '£' => 'GBP',
    'A$' => 'AUD',
    'C$' => 'CAD',
    'CHF' => 'CHF',
    '元' => 'CNY',
    'HK$' => 'HKD',
    'NZ$' => 'NZD',
    'S$' => 'SGD',
    '₹' => 'INR',
    'MX$' => 'MXN',
  })

  def self.dump(value)
    return value unless value.is_a?(self)

    "#{Monies::Digits.dump(value)} #{value.currency}"
  end

  def self.format(value, name = :default, symbol: false, code: false)
    unless formats.key?(name)
      raise ArgumentError, "#{name.inspect} is not a valid format"
    end

    return if value.nil?

    formats[name].call(value, symbol: symbol, code: code)
  end

  def self.load(string)
    return if string.nil?

    digits, currency = string.split

    Monies::Digits.load(digits, currency)
  end

  def self.parse(string)
    Parser.new(string).parse
  end

  def self._load(string)
    value, scale, currency = string.split

    new(value.to_i, scale.to_i, currency)
  end

  def initialize(value, scale, currency = self.class.currency)
    unless value.is_a?(Integer)
      raise ArgumentError, "#{value.inspect} is not a valid value argument"
    end

    unless scale.is_a?(Integer) && scale >= 0
      raise ArgumentError, "#{scale.inspect} is not a valid scale argument"
    end

    unless currency.is_a?(String)
      raise ArgumentError, "#{currency.inspect} is not a valid currency argument"
    end

    @value, @scale, @currency = value, scale, currency

    freeze
  end

  def *(other)
    if other.is_a?(Integer)
      return reduce(@value * other, @scale)
    end

    if other.is_a?(Rational)
      return self * other.numerator / other.denominator
    end

    if other.respond_to?(:to_d) && !other.is_a?(self.class)
      other = other.to_d

      sign, significant_digits, base, exponent = other.split

      value = significant_digits.to_i * sign

      length = significant_digits.length

      if exponent.positive? && length < exponent
        value *= base ** (exponent - length)
      end

      scale = other.scale

      return reduce(@value * value, @scale + scale)
    end

    raise TypeError, "#{self.class} can't be multiplied by #{other.class}"
  end

  def +(other)
    if other.respond_to?(:zero?) && other.zero?
      return self
    end

    unless other.is_a?(self.class)
      raise TypeError, "can't add #{other.class} to #{self.class}"
    end

    unless other.currency == @currency
      raise CurrencyError, "can't add #{other.currency} to #{@currency}"
    end

    add(other)
  end

  def -(other)
    if other.respond_to?(:zero?) && other.zero?
      return self
    end

    unless other.is_a?(self.class)
      raise TypeError, "can't subtract #{other.class} from #{self.class}"
    end

    unless other.currency == @currency
      raise CurrencyError, "can't subtract #{other.currency} from #{@currency}"
    end

    add(-other)
  end

  def -@
    self.class.new(-@value, @scale, @currency)
  end

  def /(other)
    div(other)
  end

  def <=>(other)
    if other.is_a?(self.class)
      unless other.currency == @currency
        raise CurrencyError, "can't compare #{other.currency} with #{@currency}"
      end

      value, other_value = @value, other.value

      if other.scale > @scale
        value *= BASE ** (other.scale - @scale)
      elsif other.scale < @scale
        other_value *= BASE ** (@scale - other.scale)
      end

      value <=> other_value
    elsif other.respond_to?(:zero?) && other.zero?
      @value <=> other
    end
  end

  include Comparable

  def _dump(_level)
    "#{@value} #{@scale} #{@currency}"
  end

  def abs
    return self unless negative?

    self.class.new(@value.abs, @scale, @currency)
  end

  def ceil(digits = 0)
    round(digits, :ceil)
  end

  def coerce(other)
    unless other.respond_to?(:zero?) && other.zero?
      raise TypeError, "#{self.class} can't be coerced into #{other.class}"
    end

    return self, other
  end

  def convert(other, currency = nil)
    if other.is_a?(self.class)
      unless currency.nil?
        raise ArgumentError, "#{self.class} can't be converted with #{other.class} and currency argument"
      end

      return self if @currency == other.currency

      return other * to_r
    end

    if other.is_a?(Integer) || other.is_a?(Rational)
      return Monies(to_r * other, currency || Monies.currency)
    end

    if defined?(BigDecimal) && other.is_a?(BigDecimal)
      return Monies(to_d * other, currency || Monies.currency)
    end

    raise TypeError, "#{self.class} can't be converted with #{other.class}"
  end

  def currency
    @currency
  end

  def div(other, digits = 16)
    unless digits.is_a?(Integer) && digits >= 1
      raise ArgumentError, 'digits must be greater than or equal to 1'
    end

    if other.respond_to?(:zero?) && other.zero?
      raise ZeroDivisionError, 'divided by 0'
    end

    if other.is_a?(self.class)
      unless other.currency == @currency
        raise CurrencyError, "can't divide #{@currency} by #{other.currency}"
      end

      scale = @scale - other.scale

      if scale.negative?
        return divide(@value * BASE ** scale.abs, 0, other.value, digits)
      else
        return divide(@value, scale, other.value, digits)
      end
    end

    if other.is_a?(Integer)
      return divide(@value, @scale, other, digits)
    end

    if other.is_a?(Rational)
      return self * other.denominator / other.numerator
    end

    if defined?(BigDecimal) && other.is_a?(BigDecimal)
      return self / Monies(other, @currency)
    end

    raise TypeError, "#{self.class} can't be divided by #{other.class}"
  end

  def floor(digits = 0)
    round(digits, :floor)
  end

  def inspect
    "#<#{self.class.name}: #{Monies::Digits.dump(self)} #{@currency}>"
  end

  def negative?
    @value.negative?
  end

  def nonzero?
    !@value.zero?
  end

  def positive?
    @value.positive?
  end

  def precision
    return 0 if @value.zero?

    @value.to_s.length
  end

  def round(digits = 0, mode = :default, half: nil)
    if half == :up
      mode = :half_up
    elsif half == :down
      mode = :half_down
    elsif half == :even
      mode = :half_even
    elsif !half.nil?
      raise ArgumentError, "invalid rounding mode: #{half.inspect}"
    end

    case mode
    when :banker, :ceil, :ceiling, :default, :down, :floor, :half_down, :half_even, :half_up, :truncate, :up
    else
      raise ArgumentError, "invalid rounding mode: #{mode.inspect}"
    end

    if digits >= @scale
      return self
    end

    n = @scale - digits

    array = @value.abs.digits

    digit = array[n - 1]

    case mode
    when :ceiling, :ceil
      round_digits!(array, n) if @value.positive?
    when :floor
      round_digits!(array, n) if @value.negative?
    when :half_down
      round_digits!(array, n) if (digit > 5 || (digit == 5 && n > 1))
    when :half_even, :banker
      round_digits!(array, n) if (digit > 5 || (digit == 5 && n > 1)) || digit == 5 && n == 1 && array[n].odd?
    when :half_up, :default
      round_digits!(array, n) if digit >= 5
    when :up
      round_digits!(array, n)
    end

    n.times { |i| array[i] = nil }

    value = array.reverse.join.to_i

    value = -value if @value.negative?

    if digits.zero?
      self.class.new(value, 0, currency)
    else
      reduce(value, digits)
    end
  end

  def scale
    @scale
  end

  def to_d
    BigDecimal(Monies::Digits.dump(self))
  end

  def to_i
    @value / BASE ** @scale
  end

  def to_r
    Rational(@value, BASE ** @scale)
  end

  alias to_s inspect

  def truncate(digits = 0)
    return self if digits >= @scale

    reduce(@value / BASE ** (@scale - digits), digits)
  end

  def value
    @value
  end

  def zero?
    @value.zero?
  end

  private

  def divide(value, scale, divisor, max_scale)
    quotient, carry = 0, 0

    value.abs.digits.reverse_each do |digit|
      dividend = carry + digit

      quotient = (quotient * BASE) + (dividend / divisor)

      carry = (dividend % divisor) * BASE
    end

    iterations = max_scale - scale

    until iterations.zero? || carry.zero?
      dividend = carry

      quotient = (quotient * BASE) + (dividend / divisor)

      carry = (dividend % divisor) * BASE

      scale += 1

      iterations -= 1
    end

    quotient = -quotient if value.negative?

    self.class.new(quotient, scale, @currency)
  end

  def add(other)
    value, other_value = @value, other.value

    if other.scale > @scale
      value *= BASE ** (other.scale - @scale)

      scale = other.scale
    else
      scale = @scale
    end

    if other.scale < @scale
      other_value *= BASE ** (@scale - other.scale)
    end

    value += other_value

    reduce(value, scale)
  end

  def reduce(value, scale)
    while scale > 0 && value.nonzero? && (value % BASE).zero?
      value = value / BASE

      scale -= 1
    end

    self.class.new(value, scale, @currency)
  end

  def round_digits!(array, index)
    if index == array.size
      array << 1
    else
      digit = array[index]

      if digit == 9
        array[index] = 0

        round_digits!(array, index + 1)
      else
        array[index] += 1
      end
    end
  end
end

def Monies(object, currency = Monies.currency)
  case object
  when Monies
    object
  when Integer
    Monies.new(object, 0, currency)
  when Rational
    Monies.new(object.numerator, 0, currency) / object.denominator
  when String
    Monies::Digits.load(object, currency)
  else
    if defined?(BigDecimal) && object.is_a?(BigDecimal)
      sign, significant_digits, base, exponent = object.split

      value = significant_digits.to_i * sign

      length = significant_digits.length

      if exponent.positive? && length < exponent
        value *= base ** (exponent - length)
      end

      scale = object.scale

      return Monies.new(value, scale, currency)
    end

    raise TypeError, "can't convert #{object.inspect} into #{Monies}"
  end
end
