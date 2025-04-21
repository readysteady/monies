# frozen_string_literal: true
require 'spec_helper'

describe Monies do
  let(:value) { 199 }
  let(:scale) { 2 }

  subject { Monies.new(value, scale, 'GBP') }

  describe '.format' do
    context 'with nil' do
      it 'returns nil' do
        expect(Monies.format(nil)).to be_nil
      end
    end

    context 'with zero' do
      it 'returns string' do
        expect(Monies.format(0)).to eq('0.00')
      end
    end

    context 'with instance' do
      it 'returns string' do
        expect(Monies.format(Monies.new(0, 0, 'GBP'))).to eq('0.00')
        expect(Monies.format(Monies.new(1, 0, 'GBP'))).to eq('1.00')
        expect(Monies.format(Monies.new(12, 2, 'GBP'))).to eq('0.12')
        expect(Monies.format(Monies.new(123, 2, 'GBP'))).to eq('1.23')
        expect(Monies.format(Monies.new(1, 5, 'GBP'))).to eq('0.00')
        expect(Monies.format(Monies.new(66, 3, 'GBP'))).to eq('0.06')
      end

      it 'uses the scale defined by the format' do
        expect(Monies.format(Monies.new(1234567, 3, 'GBP'))).to eq('1,234.56')
      end

      it 'includes thousands separators' do
        expect(Monies.format(Monies.new(1011000, 0, 'GBP'))).to eq('1,011,000.00')
      end

      context 'with negative instance' do
        it 'includes a minus sign' do
          expect(Monies.format(Monies.new(-75, 2, 'GBP'))).to eq('-0.75')
          expect(Monies.format(Monies.new(-1234567, 3, 'GBP'))).to eq('-1,234.56')
        end
      end

      context 'with format name' do
        it 'uses the separators defined by the format' do
          expect(Monies.format(Monies.new(101100011, 2, 'GBP'), :eu)).to eq('1.011.000,11')
        end
      end

      context 'with invalid format name' do
        it 'raises an exception' do
          expect { Monies.format(subject, :other) }.to raise_error(ArgumentError)
        end
      end

      context 'with symbol keyword argument' do
        it 'includes a currency symbol' do
          expect(Monies.format(subject, symbol: true)).to eq('£1.99')
        end
      end

      context 'with code keyword argument' do
        it 'includes a currency code' do
          expect(Monies.format(subject, code: true)).to eq('1.99 GBP')
        end
      end

      context 'with symbol and code keyword arguments' do
        it 'raises an exception' do
          expect { Monies.format(subject, symbol: true, code: true) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '.parse' do
    it 'returns an instance' do
      expect(Monies.parse('1.99 GBP')).to eq(Monies.new(199, 2, 'GBP'))
      expect(Monies.parse('1.99 EUR')).to eq(Monies.new(199, 2, 'EUR'))
    end

    it 'parses input with currency symbols' do
      expect(Monies.parse('£1.99')).to eq(Monies.new(199, 2, 'GBP'))
      expect(Monies.parse('€1,99')).to eq(Monies.new(199, 2, 'EUR'))
    end

    it 'parses input with thousand separators' do
      expect(Monies.parse('1,999.00 GBP')).to eq(Monies.new(1999, 0, 'GBP'))
      expect(Monies.parse('1.999,00 EUR')).to eq(Monies.new(1999, 0, 'EUR'))
      expect(Monies.parse("1\u{2009}999,00 EUR")).to eq(Monies.new(1999, 0, 'EUR'))
    end

    it 'parses input with ambiguous separators' do
      expect(Monies.parse('€123.456')).to eq(Monies.new(123456, 3, 'EUR'))
    end

    it 'parses input with minus sign' do
      expect(Monies.parse('-1.99 GBP')).to eq(Monies.new(-199, 2, 'GBP'))
      expect(Monies.parse('-£1.99')).to eq(Monies.new(-199, 2, 'GBP'))
      expect(Monies.parse('£-1.99')).to eq(Monies.new(-199, 2, 'GBP'))
    end

    it 'parses input without decimal places' do
      expect(Monies.parse('1999 GBP')).to eq(Monies.new(1999, 0, 'GBP'))
      expect(Monies.parse('1,999 GBP')).to eq(Monies.new(1999, 0, 'GBP'))
    end

    context 'with currency' do
      before { Monies.currency = 'GBP' }

      it 'parses input without currency code' do
        expect(Monies.parse('1999')).to eq(Monies.new(1999, 0, 'GBP'))
      end
    end

    context 'without currency' do
      before { Monies.currency = nil }

      it 'raises an exception for input without currency code' do
        expect { Monies.parse('1999') }.to raise_error(ArgumentError)
      end
    end

    context 'with invalid input' do
      it 'raises an exception' do
        expect { Monies.parse('abc') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#initialize' do
    context 'with invalid value' do
      it 'raises an exception' do
        expect { Monies.new('123', scale, 'GBP') }.to raise_error(ArgumentError)
      end
    end

    context 'with invalid scale' do
      it 'raises an exception' do
        expect { Monies.new(value, -1, 'GBP') }.to raise_error(ArgumentError)
      end
    end

    context 'with invalid currency' do
      it 'raises an exception' do
        expect { Monies.new(value, scale, 123) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#*' do
    context 'with integer' do
      it 'returns an instance' do
        expect(subject * 100).to eq(Monies.new(199, 0, 'GBP'))
      end

      it 'reduces to remove trailing zeroes' do
        expect(Monies.new(1000, 1, 'GBP') * 1).to eq(Monies.new(100, 0, 'GBP'))
      end
    end

    context 'with rational' do
      it 'returns an instance' do
        expect(subject * Rational(1, 5)).to eq(Monies.new(398, 3, 'GBP'))
      end

      it 'reduces to remove trailing zeroes' do
        expect(Monies.new(151, 2, 'GBP') * Rational(1000)).to eq(Monies.new(1510, 0, 'GBP'))
      end
    end

    context 'with bigdecimal' do
      it 'returns an instance' do
        expect(subject * BigDecimal('0.2')).to eq(Monies.new(398, 3, 'GBP'))
      end

      it 'reduces to remove trailing zeroes' do
        expect(Monies.new(151, 2, 'GBP') * BigDecimal(1000)).to eq(Monies.new(1510, 0, 'GBP'))
      end
    end

    context 'with percentage' do
      it 'returns an instance' do
        expect(subject * Percentage.new(20)).to eq(Monies.new(398, 3, 'GBP'))
      end
    end

    context 'with instance' do
      it 'raises an exception' do
        expect { subject * subject }.to raise_error(TypeError)
        expect { subject * Monies.new(value, scale, 'EUR') }.to raise_error(TypeError)
      end
    end

    context 'with another type of object' do
      it 'raises an exception' do
        expect { subject * Object.new }.to raise_error(TypeError)
      end
    end
  end

  describe '#+' do
    context 'with zero' do
      it 'returns itself' do
        result = subject + 0

        expect(result.object_id).to eq(subject.object_id)
      end

      it 'is commutative' do
        result = 0 + subject

        expect(result.object_id).to eq(subject.object_id)
      end
    end

    context 'with instance' do
      it 'returns an instance' do
        expect(subject + subject).to eq(Monies.new(398, scale, 'GBP'))
        expect(subject + Monies.new(1, 0, 'GBP')).to eq(Monies.new(299, 2, 'GBP'))
        expect(subject + Monies.new(12345, 4, 'GBP')).to eq(Monies.new(32245, 4, 'GBP'))
        expect(subject + Monies.new(19999, 4, 'GBP')).to eq(Monies.new(39899, 4, 'GBP'))
      end
    end

    context 'with another currency' do
      it 'raises an exception' do
        expect { subject + Monies.new(value, scale, 'EUR') }.to raise_error(Monies::CurrencyError)
      end
    end

    context 'with another type of object' do
      it 'raises an exception' do
        expect { subject + 123 }.to raise_error(TypeError)
        expect { 123 + subject }.to raise_error(TypeError)
      end
    end
  end

  describe '#-' do
    context 'with instance' do
      it 'returns an instance' do
        expect(subject - Monies.new(value, scale, 'GBP')).to eq(Monies.new(0, 0, 'GBP'))
      end
    end

    context 'with zero' do
      it 'returns itself' do
        result = subject - 0

        expect(result.object_id).to eq(subject.object_id)
      end
    end

    context 'with another currency' do
      it 'raises an exception' do
        expect { subject -  Monies.new(value, scale, 'EUR') }.to raise_error(Monies::CurrencyError)
      end
    end

    context 'with another type of object' do
      it 'raises an exception' do
        expect { subject - 123 }.to raise_error(TypeError)
      end
    end
  end

  describe '#-@' do
    it 'returns an instance' do
      result = -subject

      expect(result).to eq(Monies.new(-value, scale, 'GBP'))
    end
  end

  describe '#/' do
    context 'with instance' do
      it 'returns an instance' do
        expect(subject / Monies.new(100, 0, 'GBP')).to eq(Monies.new(199, 4, 'GBP'))
        expect(Monies.new(100, 0, 'GBP') / Monies.new(20, 0, 'GBP')).to eq(Monies.new(5, 0, 'GBP'))
        expect(Monies.new(1002, 1, 'GBP') / Monies.new(20, 0, 'GBP')).to eq(Monies.new(501, 2, 'GBP'))
        expect(Monies.new(92, 2, 'GBP') / Monies.new(4, 1, 'GBP')).to eq(Monies.new(23, 1, 'GBP'))
        expect(Monies.new(12, 5, 'GBP') / Monies.new(8, 3, 'GBP')).to eq(Monies.new(15, 3, 'GBP'))
        expect(Monies.new(1, 1, 'GBP') / Monies.new(5, 4, 'GBP')).to eq(Monies.new(200, 0, 'GBP'))
        expect(Monies.new(100, 0, 'GBP') / Monies.new(-20, 0, 'GBP')).to eq(Monies.new(-5, 0, 'GBP'))
        expect(Monies.new(-100, 0, 'GBP') / Monies.new(20, 0, 'GBP')).to eq(Monies.new(-5, 0, 'GBP'))
        expect(Monies.new(-100, 0, 'GBP') / Monies.new(-20, 0, 'GBP')).to eq(Monies.new(5, 0, 'GBP'))
      end
    end

    context 'with integer' do
      it 'returns an instance' do
        expect(subject / 100).to eq(Monies.new(199, 4, 'GBP'))
        expect(Monies.new(888, 0, 'GBP') / 8).to eq(Monies.new(111, 0, 'GBP'))
        expect(Monies.new(3052, 0, 'GBP') / 4).to eq(Monies.new(763, 0, 'GBP'))
        expect(Monies.new(185184, 0, 'GBP') / 1500).to eq(Monies.new(123456, 3, 'GBP'))
        expect(Monies.new(7125, 2, 'GBP') / 3).to eq(Monies.new(2375, 2, 'GBP'))
        expect(Monies.new(1224, 3, 'GBP') / 8).to eq(Monies.new(153, 3, 'GBP'))
        expect(Monies.new(917, 0, 'GBP') / 6).to eq(Monies.new(1528333333333333333, 16, 'GBP'))
        expect(Monies.new(1999, 3, 'GBP') / 3).to eq(Monies.new(6663333333333333, 16, 'GBP'))
        expect(Monies.new(888, 0, 'GBP') / -8).to eq(Monies.new(-111, 0, 'GBP'))
        expect(Monies.new(-888, 0, 'GBP') / 8).to eq(Monies.new(-111, 0, 'GBP'))
        expect(Monies.new(-888, 0, 'GBP') / -8).to eq(Monies.new(111, 0, 'GBP'))
      end
    end

    context 'with rational' do
      it 'returns an instance' do
        expect(subject / Rational(100)).to eq(Monies.new(199, 4, 'GBP'))
        expect(Monies.new(92, 2, 'GBP') / Rational(2, 5)).to eq(Monies.new(23, 1, 'GBP'))
        expect(Monies.new(12, 5, 'GBP') / Rational(1, 125)).to eq(Monies.new(15, 3, 'GBP'))
        expect(Monies.new(1, 1, 'GBP') / Rational(1, 2000)).to eq(Monies.new(200, 0, 'GBP'))
      end
    end

    context 'with bigdecimal' do
      it 'returns an instance' do
        expect(subject / BigDecimal(100)).to eq(Monies.new(199, 4, 'GBP'))
        expect(Monies.new(92, 2, 'GBP') /  BigDecimal('0.4')).to eq(Monies.new(23, 1, 'GBP'))
        expect(Monies.new(12, 5, 'GBP') / BigDecimal('0.008')).to eq(Monies.new(15, 3, 'GBP'))
        expect(Monies.new(1, 1, 'GBP') / BigDecimal('0.0005')).to eq(Monies.new(200, 0, 'GBP'))
      end
    end

    context 'with another currency' do
      it 'raises an exception' do
        expect { subject / Monies.new(value, scale, 'EUR') }.to raise_error(Monies::CurrencyError)
      end
    end

    context 'with zero' do
      it 'raises an exception' do
        expect { subject / 0 }.to raise_error(ZeroDivisionError)
      end
    end

    context 'with another type of object' do
      it 'raises an exception' do
        expect { subject / 1.23 }.to raise_error(TypeError)
      end
    end
  end

  describe '#<=>' do
    context 'with instance of same value' do
      it 'returns zero' do
        expect(subject <=> subject).to eq(0)
        expect(Monies.new(1, 0, 'GBP') <=> Monies.new(100, 2, 'GBP')).to eq(0)
      end
    end

    context 'with instance of greater value' do
      it 'returns minus one' do
        expect(subject <=> Monies.new(199, 1, 'GBP')).to eq(-1)
      end
    end

    context 'with instance of lesser value' do
      it 'returns one' do
        expect(subject <=> Monies.new(199, 3, 'GBP')).to eq(1)
      end
    end

    context 'with another currency' do
      it 'raises an exception' do
        expect { subject <=> Monies.new(199, 1, 'EUR') }.to raise_error(Monies::CurrencyError)
      end
    end

    context 'with zero' do
      it 'returns result of value compared to zero' do
        expect(Monies.new(1, scale, 'GBP') <=> 0).to eq(1)
        expect(Monies.new(0, 0, 'GBP') <=> 0).to eq(0)
        expect(Monies.new(-1, scale, 'GBP') <=> 0).to eq(-1)
      end
    end

    context 'with another type of object' do
      it 'returns nil' do
        expect(subject <=> nil).to be_nil
        expect(subject <=> 123).to be_nil
      end
    end
  end

  describe '#abs' do
    context 'with positive instance' do
      it 'returns itself' do
        result = subject.abs

        expect(result.object_id).to eq(subject.object_id)
      end
    end

    context 'with negative instance' do
      let(:instance) { Monies.new(-199, scale, 'GBP') }

      it 'returns a positive instance' do
        result = instance.abs

        expect(result).to eq(subject)
      end
    end
  end

  describe '#allocate' do
    it 'returns an array' do
      expect(Monies.new(100, 0, 'GBP').allocate(3, 0)).to eq([
        Monies.new(33, 0, 'GBP'),
        Monies.new(33, 0, 'GBP'),
        Monies.new(34, 0, 'GBP'),
      ])

      expect(Monies.new(100, 0, 'GBP').allocate(3, 2)).to eq([
        Monies.new(3333, 2, 'GBP'),
        Monies.new(3333, 2, 'GBP'),
        Monies.new(3334, 2, 'GBP'),
      ])

      expect(Monies.new(5, 2, 'GBP').allocate(2, 2)).to eq([
        Monies.new(2, 2, 'GBP'),
        Monies.new(3, 2, 'GBP'),
      ])
    end

    context 'with integer less than 1' do
      it 'raises an exception' do
        expect { Monies.new(100, 0, 'GBP').allocate(0, 0) }.to raise_error(ArgumentError)
      end
    end

    context 'with another type of object' do
      it 'raises an exception' do
        expect { Monies.new(100, 0, 'GBP').allocate(Object.new, 0) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#ceil' do
    it 'returns an instance' do
      expect(Monies.new(314159, 5, 'GBP').ceil).to eq(Monies.new(4, 0, 'GBP'))
      expect(Monies.new(-91, 1, 'GBP').ceil).to eq(Monies.new(-9, 0, 'GBP'))
      expect(Monies.new(314159, 5, 'GBP').ceil(3)).to eq(Monies.new(3142, 3, 'GBP'))
    end
  end

  describe '#convert' do
    let(:rate) { 2 }
    let(:converted) { Monies.new(398, 2, 'EUR') }

    context 'with instance' do
      context 'with the same currency' do
        it 'returns itself' do
          result = subject.convert(subject)

          expect(result.object_id).to eq(subject.object_id)
        end
      end

      context 'with another currency' do
        it 'returns an instance' do
          result = subject.convert(Monies.new(rate, 0, 'EUR'))

          expect(result).to eq(converted)
        end
      end

      context 'with currency argument' do
        it 'raises an exception' do
          expect { subject.convert(subject, 'GBP') }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with integer' do
      it 'returns an instance' do
        result = subject.convert(rate, 'EUR')

        expect(result).to eq(converted)
      end

      context 'without currency argument' do
        it 'raises an exception' do
          expect { subject.convert(rate) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with rational' do
      it 'returns an instance' do
        result = subject.convert(Rational(rate), 'EUR')

        expect(result).to eq(converted)
      end

      context 'without currency argument' do
        it 'raises an exception' do
          expect { subject.convert(Rational(rate)) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with bigdecimal' do
      it 'returns an instance' do
        result = subject.convert(BigDecimal(rate), 'EUR')

        expect(result).to eq(converted)
      end

      context 'without currency argument' do
        it 'raises an exception' do
          expect { subject.convert(BigDecimal(rate)) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with another type of object' do
      it 'raises an exception' do
        expect { subject.convert(1.23, 'EUR') }.to raise_error(TypeError)
      end
    end
  end

  describe '#currency' do
    it 'returns the currency code' do
      expect(subject.currency).to eq('GBP')
    end
  end

  describe '#div' do
    let(:subject) { Monies.new(1, 0, 'GBP') }

    context 'without digits argument' do
      it 'limits fractional digits' do
        result = subject.div(9)

        expect(result).to eq(Monies.new(1111111111111111, 16, 'GBP'))
      end
    end

    context 'with digits argument' do
      it 'includes at most that many fractional digits' do
        result = subject.div(9, 32)

        expect(result).to eq(Monies.new(11111111111111111111111111111111, 32, 'GBP'))
      end
    end
  end

  describe '#fix' do
    it 'returns an instance' do
      expect(Monies.new(123, 2, 'GBP').fix).to eq(Monies.new(1, 0, 'GBP'))
      expect(Monies.new(123, 1, 'GBP').fix).to eq(Monies.new(12, 0, 'GBP'))
      expect(Monies.new(123, 0, 'GBP').fix).to eq(Monies.new(123, 0, 'GBP'))
    end
  end

  describe '#floor' do
    it 'returns an instance' do
      expect(Monies.new(314159, 5, 'GBP').floor).to eq(Monies.new(3, 0, 'GBP'))
      expect(Monies.new(-91, 1, 'GBP').floor).to eq(Monies.new(-10, 0, 'GBP'))
      expect(Monies.new(314159, 5, 'GBP').floor(3)).to eq(Monies.new(3141, 3, 'GBP'))
    end
  end

  describe '#frac' do
    it 'returns an instance' do
      expect(Monies.new(123, 2, 'GBP').frac).to eq(Monies.new(23, 2, 'GBP'))
      expect(Monies.new(123, 1, 'GBP').frac).to eq(Monies.new(3, 1, 'GBP'))
      expect(Monies.new(123, 0, 'GBP').frac).to eq(Monies.new(0, 0, 'GBP'))
    end
  end

  describe '#inspect' do
    it 'returns a string' do
      expect(subject.inspect).to eq('#<Monies: 1.99 GBP>')
    end
  end

  describe '#negative?' do
    context 'with negative value' do
      subject { Monies.new(-199, scale, 'GBP') }

      it 'returns true' do
        expect(subject.negative?).to eq(true)
      end
    end

    context 'with positive value' do
      subject { Monies.new(199, scale, 'GBP') }

      it 'returns false' do
        expect(subject.negative?).to eq(false)
      end
    end
  end

  describe '#nonzero?' do
    context 'with zero value' do
      subject { Monies.new(0, 0, 'GBP') }

      it 'returns false' do
        expect(subject.nonzero?).to eq(false)
      end
    end

    context 'with non-zero value' do
      subject { Monies.new(199, scale, 'GBP') }

      it 'returns true' do
        expect(subject.nonzero?).to eq(true)
      end
    end
  end

  describe '#positive?' do
    context 'with negative value' do
      subject { Monies.new(-199, scale, 'GBP') }

      it 'returns false' do
        expect(subject.positive?).to eq(false)
      end
    end

    context 'with positive value' do
      subject { Monies.new(199, scale, 'GBP') }

      it 'returns true' do
        expect(subject.positive?).to eq(true)
      end
    end
  end

  describe '#precision' do
    it 'returns an integer' do
      expect(Monies.new(0, 0, 'GBP').precision).to eq(0)
      expect(Monies.new(1, 0, 'GBP').precision).to eq(1)
      expect(Monies.new(12, 0, 'GBP').precision).to eq(2)
      expect(Monies.new(12, 1, 'GBP').precision).to eq(2)
      expect(Monies.new(12, 2, 'GBP').precision).to eq(2)
      expect(Monies.new(123, 0, 'GBP').precision).to eq(3)
      expect(Monies.new(123, 1, 'GBP').precision).to eq(3)
      expect(Monies.new(123, 2, 'GBP').precision).to eq(3)
      expect(Monies.new(123, 3, 'GBP').precision).to eq(3)
    end
  end

  describe '#round' do
    context 'with no arguments' do
      it 'returns an instance' do
        expect(subject.round).to eq(Monies.new(2, 0, 'GBP'))
      end
    end

    context 'with integer argument' do
      it 'returns an instance' do
        expect(Monies.new(199, 2, 'GBP').round(0)).to eq(Monies.new(2, 0, 'GBP'))

        expect(Monies.new(1, 3, 'GBP').round(2)).to eq(Monies.new(0, 0, 'GBP'))
        expect(Monies.new(-1, 3, 'GBP').round(2)).to eq(Monies.new(0, 0, 'GBP'))
        expect(Monies.new(-1990, 2, 'GBP').round(0)).to eq(Monies.new(-20, 0, 'GBP'))

        expect(Monies.new(1990, 2, 'GBP').round(0)).to eq(Monies.new(20, 0, 'GBP'))
        expect(Monies.new(9998, 2, 'GBP').round(0)).to eq(Monies.new(100, 0, 'GBP'))
        expect(Monies.new(43299, 3, 'GBP').round(2)).to eq(Monies.new(433, 1, 'GBP'))
        expect(Monies.new(34997, 3, 'GBP').round(2)).to eq(Monies.new(35, 0, 'GBP'))
        expect(Monies.new(59999, 4, 'GBP').round(3)).to eq(Monies.new(6, 0, 'GBP'))

        expect(Monies.new(102, 3, 'GBP').round(2)).to eq(Monies.new(1, 1, 'GBP'))
        expect(Monies.new(104, 3, 'GBP').round(2)).to eq(Monies.new(1, 1, 'GBP'))
        expect(Monies.new(105, 3, 'GBP').round(2)).to eq(Monies.new(11, 2, 'GBP'))
        expect(Monies.new(106, 3, 'GBP').round(2)).to eq(Monies.new(11, 2, 'GBP'))
        expect(Monies.new(108, 3, 'GBP').round(2)).to eq(Monies.new(11, 2, 'GBP'))
      end

      context 'when integer argument is greater than or equal to the instance scale' do
        it 'returns itself' do
          result = subject.round(10)

          expect(result.object_id).to eq(subject.object_id)
        end
      end

      context 'with :up mode' do
        it 'rounds away from zero' do
          expect(Monies.new(235, 1, 'GBP').round(0, :up)).to eq(Monies.new(24, 0, 'GBP'))
          expect(Monies.new(-235, 1, 'GBP').round(0, :up)).to eq(Monies.new(-24, 0, 'GBP'))
        end
      end

      context 'with :down or :truncate mode' do
        it 'rounds towards zero' do
          expect(Monies.new(235, 1, 'GBP').round(0, :down)).to eq(Monies.new(23, 0, 'GBP'))
          expect(Monies.new(-235, 1, 'GBP').round(0, :down)).to eq(Monies.new(-23, 0, 'GBP'))
        end
      end

      context 'with :half_up or :default mode' do
        it 'rounds up half and above' do
          expect(Monies.new(235, 1, 'GBP').round(0, :half_up)).to eq(Monies.new(24, 0, 'GBP'))
          expect(Monies.new(-235, 1, 'GBP').round(0, :half_up)).to eq(Monies.new(-24, 0, 'GBP'))

          expect(Monies.new(125, 1, 'GBP').round(0, :half_up)).to eq(Monies.new(13, 0, 'GBP'))
          expect(Monies.new(135, 1, 'GBP').round(0, :half_up)).to eq(Monies.new(14, 0, 'GBP'))

          expect(Monies.new(215, 2, 'GBP').round(1, :half_up)).to eq(Monies.new(22, 1, 'GBP'))
          expect(Monies.new(225, 2, 'GBP').round(1, :half_up)).to eq(Monies.new(23, 1, 'GBP'))
          expect(Monies.new(235, 2, 'GBP').round(1, :half_up)).to eq(Monies.new(24, 1, 'GBP'))

          expect(Monies.new(-215, 2, 'GBP').round(1, :half_up)).to eq(Monies.new(-22, 1, 'GBP'))
          expect(Monies.new(-225, 2, 'GBP').round(1, :half_up)).to eq(Monies.new(-23, 1, 'GBP'))
          expect(Monies.new(-235, 2, 'GBP').round(1, :half_up)).to eq(Monies.new(-24, 1, 'GBP'))

          expect(Monies.new(713645, 5, 'GBP').round(4, :half_up)).to eq(Monies.new(71365, 4, 'GBP'))
          expect(Monies.new(71364501, 7, 'GBP').round(4, :half_up)).to eq(Monies.new(71365, 4, 'GBP'))
          expect(Monies.new(71364499, 7, 'GBP').round(4, :half_up)).to eq(Monies.new(71364, 4, 'GBP'))

          expect(Monies.new(-713645, 5, 'GBP').round(4, :half_up)).to eq(Monies.new(-71365, 4, 'GBP'))
          expect(Monies.new(-71364501, 7, 'GBP').round(4, :half_up)).to eq(Monies.new(-71365, 4, 'GBP'))
          expect(Monies.new(-71364499, 7, 'GBP').round(4, :half_up)).to eq(Monies.new(-71364, 4, 'GBP'))
        end
      end

      context 'with :half_down mode' do
        it 'rounds down half and below' do
          expect(Monies.new(235, 1, 'GBP').round(0, :half_down)).to eq(Monies.new(23, 0, 'GBP'))
          expect(Monies.new(-235, 1, 'GBP').round(0, :half_down)).to eq(Monies.new(-23, 0, 'GBP'))

          expect(Monies.new(125, 1, 'GBP').round(0, :half_down)).to eq(Monies.new(12, 0, 'GBP'))
          expect(Monies.new(135, 1, 'GBP').round(0, :half_down)).to eq(Monies.new(13, 0, 'GBP'))

          expect(Monies.new(215, 2, 'GBP').round(1, :half_down)).to eq(Monies.new(21, 1, 'GBP'))
          expect(Monies.new(225, 2, 'GBP').round(1, :half_down)).to eq(Monies.new(22, 1, 'GBP'))
          expect(Monies.new(235, 2, 'GBP').round(1, :half_down)).to eq(Monies.new(23, 1, 'GBP'))

          expect(Monies.new(-215, 2, 'GBP').round(1, :half_down)).to eq(Monies.new(-21, 1, 'GBP'))
          expect(Monies.new(-225, 2, 'GBP').round(1, :half_down)).to eq(Monies.new(-22, 1, 'GBP'))
          expect(Monies.new(-235, 2, 'GBP').round(1, :half_down)).to eq(Monies.new(-23, 1, 'GBP'))

          expect(Monies.new(713645, 5, 'GBP').round(4, :half_down)).to eq(Monies.new(71364, 4, 'GBP'))
          expect(Monies.new(71364501, 7, 'GBP').round(4, :half_down)).to eq(Monies.new(71365, 4, 'GBP'))
          expect(Monies.new(71364499, 7, 'GBP').round(4, :half_down)).to eq(Monies.new(71364, 4, 'GBP'))

          expect(Monies.new(-713645, 5, 'GBP').round(4, :half_down)).to eq(Monies.new(-71364, 4, 'GBP'))
          expect(Monies.new(-71364501, 7, 'GBP').round(4, :half_down)).to eq(Monies.new(-71365, 4, 'GBP'))
          expect(Monies.new(-71364499, 7, 'GBP').round(4, :half_down)).to eq(Monies.new(-71364, 4, 'GBP'))
        end
      end

      context 'with :half_even or :banker mode' do
        it 'rounds towards the even neighbour' do
          expect(Monies.new(235, 1, 'GBP').round(0, :half_even)).to eq(Monies.new(24, 0, 'GBP'))
          expect(Monies.new(245, 1, 'GBP').round(0, :half_even)).to eq(Monies.new(24, 0, 'GBP'))
          expect(Monies.new(-235, 1, 'GBP').round(0, :half_even)).to eq(Monies.new(-24, 0, 'GBP'))
          expect(Monies.new(-245, 1, 'GBP').round(0, :half_even)).to eq(Monies.new(-24, 0, 'GBP'))

          expect(Monies.new(125, 1, 'GBP').round(0, :half_even)).to eq(Monies.new(12, 0, 'GBP'))
          expect(Monies.new(135, 1, 'GBP').round(0, :half_even)).to eq(Monies.new(14, 0, 'GBP'))

          expect(Monies.new(215, 2, 'GBP').round(1, :half_even)).to eq(Monies.new(22, 1, 'GBP'))
          expect(Monies.new(225, 2, 'GBP').round(1, :half_even)).to eq(Monies.new(22, 1, 'GBP'))
          expect(Monies.new(235, 2, 'GBP').round(1, :half_even)).to eq(Monies.new(24, 1, 'GBP'))

          expect(Monies.new(-215, 2, 'GBP').round(1, :half_even)).to eq(Monies.new(-22, 1, 'GBP'))
          expect(Monies.new(-225, 2, 'GBP').round(1, :half_even)).to eq(Monies.new(-22, 1, 'GBP'))
          expect(Monies.new(-235, 2, 'GBP').round(1, :half_even)).to eq(Monies.new(-24, 1, 'GBP'))

          expect(Monies.new(713645, 5, 'GBP').round(4, :half_even)).to eq(Monies.new(71364, 4, 'GBP'))
          expect(Monies.new(71364501, 7, 'GBP').round(4, :half_even)).to eq(Monies.new(71365, 4, 'GBP'))
          expect(Monies.new(71364499, 7, 'GBP').round(4, :half_even)).to eq(Monies.new(71364, 4, 'GBP'))

          expect(Monies.new(-713645, 5, 'GBP').round(4, :half_even)).to eq(Monies.new(-71364, 4, 'GBP'))
          expect(Monies.new(-71364501, 7, 'GBP').round(4, :half_even)).to eq(Monies.new(-71365, 4, 'GBP'))
          expect(Monies.new(-71364499, 7, 'GBP').round(4, :half_even)).to eq(Monies.new(-71364, 4, 'GBP'))
        end
      end

      context 'with :ceiling or :ceil mode' do
        it 'rounds towards positive infinity' do
          expect(Monies.new(235, 1, 'GBP').round(0, :ceil)).to eq(Monies.new(24, 0, 'GBP'))
          expect(Monies.new(-235, 1, 'GBP').round(0, :ceil)).to eq(Monies.new(-23, 0, 'GBP'))
        end
      end

      context 'with :floor mode' do
        it 'rounds towards negative infinity' do
          expect(Monies.new(235, 1, 'GBP').round(0, :floor)).to eq(Monies.new(23, 0, 'GBP'))
          expect(Monies.new(-235, 1, 'GBP').round(0, :floor)).to eq(Monies.new(-24, 0, 'GBP'))
        end
      end

      context 'with invalid rounding mode' do
        it 'raises an exception' do
          expect { subject.round(0, :foo) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#to_d' do
    it 'returns a bigdecimal' do
      expect(subject.to_d).to eq(BigDecimal('1.99'))
    end
  end

  describe '#to_i' do
    it 'returns an integer' do
      expect(Monies.new(0, 0, 'GBP').to_i).to eq(0)
      expect(Monies.new(1, 0, 'GBP').to_i).to eq(1)
      expect(Monies.new(12, 2, 'GBP').to_i).to eq(0)
      expect(Monies.new(123, 2, 'GBP').to_i).to eq(1)
      expect(Monies.new(999, 2, 'GBP').to_i).to eq(9)
    end
  end

  describe '#to_r' do
    it 'returns a rational' do
      expect(subject.to_r).to eq(Rational(199, 100))
    end
  end

  describe '#truncate' do
    subject { Monies.new(199, scale, 'GBP') }

    context 'with no arguments' do
      it 'returns an instance' do
        result = subject.truncate

        expect(result).to eq(Monies.new(1, 0, 'GBP'))
      end
    end

    context 'with integer argument' do
      it 'truncates the value to the given number of digits' do
        result = subject.truncate(1)

        expect(result).to eq(Monies.new(19, 1, 'GBP'))
      end

      it 'reduces to remove trailing zeroes' do
        subject = Monies.new(1001, 3, 'GBP')

        result = subject.truncate(2)

        expect(result).to eq(Monies.new(1, 0, 'GBP'))
      end
    end
  end

  describe '#value' do
    it 'returns the value' do
      expect(subject.value).to eq(199)
    end
  end

  describe '#zero?' do
    context 'with zero value' do
      subject { Monies.new(0, 0, 'GBP') }

      it 'returns true' do
        expect(subject.zero?).to eq(true)
      end
    end

    context 'with non-zero value' do
      subject { Monies.new(199, scale, 'GBP') }

      it 'returns false' do
        expect(subject.zero?).to eq(false)
      end
    end
  end
end

RSpec.describe 'Monies method' do
  let(:value) { 199 }
  let(:scale) { 2 }

  subject { Monies.new(value, scale, 'GBP') }

  context 'with instance' do
    it 'returns the instance' do
      result = Monies(subject)

      expect(result.object_id).to eq(subject.object_id)
    end
  end

  context 'with integer' do
    it 'returns an instance' do
      expect(Monies(199, 'GBP')).to eq(Monies.new(value, 0, 'GBP'))
    end
  end

  context 'with rational' do
    it 'returns an instance' do
      expect(Monies(Rational(199, 1), 'GBP')).to eq(Monies.new(value, 0, 'GBP'))
      expect(Monies(Rational(2, 5), 'GBP')).to eq(Monies.new(4, 1, 'GBP'))
      expect(Monies(Rational(1, 125), 'GBP')).to eq(Monies.new(8, 3, 'GBP'))
      expect(Monies(Rational(1, 2000), 'GBP')).to eq(Monies.new(5, 4, 'GBP'))
    end
  end

  context 'with bigdecimal' do
    it 'returns an instance' do
      expect(Monies(BigDecimal('444'), 'GBP')).to eq(Monies.new(444, 0, 'GBP'))
      expect(Monies(BigDecimal('400'), 'GBP')).to eq(Monies.new(400, 0, 'GBP'))
      expect(Monies(BigDecimal('40'), 'GBP')).to eq(Monies.new(40, 0, 'GBP'))
      expect(Monies(BigDecimal('4'), 'GBP')).to eq(Monies.new(4, 0, 'GBP'))
      expect(Monies(BigDecimal('0.444'), 'GBP')).to eq(Monies.new(444, 3, 'GBP'))
      expect(Monies(BigDecimal('0.400'), 'GBP')).to eq(Monies.new(4, 1, 'GBP'))
      expect(Monies(BigDecimal('0.040'), 'GBP')).to eq(Monies.new(4, 2, 'GBP'))
      expect(Monies(BigDecimal('0.004'), 'GBP')).to eq(Monies.new(4, 3, 'GBP'))
    end
  end

  context 'with string' do
    it 'returns an instance' do
      expect(Monies('1.99', 'GBP')).to eq(subject)
    end
  end

  context 'with invalid string' do
    it 'raises an exception' do
      expect { Monies('', 'GBP') }.to raise_error(ArgumentError)
    end
  end

  context 'with another type of object' do
    it 'raises an exception' do
      expect { Monies(1.23) }.to raise_error(TypeError)
    end
  end
end
