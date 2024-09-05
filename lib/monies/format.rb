# frozen_string_literal: true

class Monies::Format
  def call(instance, symbol: false, code: false)
    if symbol && code
      raise ArgumentError, "can't format with both symbol and code keyword arguments"
    end

    digits = Monies::Digits.dump(instance, scale: scale, zero: zero, separator: separator, thousands_separator: thousands_separator)

    if symbol
      Monies.symbols.fetch_key(instance.currency) + digits
    elsif code
      "#{digits} #{instance.currency}"
    else
      digits
    end
  end
end

class Monies::Format::EN < Monies::Format
  def scale
    2
  end

  def zero
    '0.00'
  end

  def separator
    '.'
  end

  def thousands_separator
    ','
  end
end

class Monies::Format::EU < Monies::Format
  def scale
    2
  end

  def zero
    '0,00'
  end

  def separator
    ','
  end

  def thousands_separator
    '.'
  end
end
