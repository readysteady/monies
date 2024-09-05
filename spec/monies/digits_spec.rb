require 'spec_helper'

describe Monies::Digits do
  let(:currency) { 'GBP' }

  describe '.dump' do
    it 'returns a string' do
      expect(described_class.dump(Monies.new(0, 0, currency))).to eq('0')
      expect(described_class.dump(Monies.new(1, 0, currency))).to eq('1')
      expect(described_class.dump(Monies.new(123, 2, currency))).to eq('1.23')
      expect(described_class.dump(Monies.new(1, 3, currency))).to eq('0.001')
      expect(described_class.dump(Monies.new(66, 3, currency))).to eq('0.066')
    end

    context 'with negative instances' do
      it 'includes a minus sign' do
        expect(described_class.dump(Monies.new(-1, 0, currency))).to eq('-1')
        expect(described_class.dump(Monies.new(-123, 2, currency))).to eq('-1.23')
        expect(described_class.dump(Monies.new(-1, 3, currency))).to eq('-0.001')
      end
    end

    context 'with scale argument' do
      it 'returns the given number of fractional digits' do
        expect(described_class.dump(Monies.new(1, 0, currency), scale: 2)).to eq('1.00')
        expect(described_class.dump(Monies.new(1, 1, currency), scale: 2)).to eq('0.10')
        expect(described_class.dump(Monies.new(1, 2, currency), scale: 2)).to eq('0.01')
        expect(described_class.dump(Monies.new(1, 3, currency), scale: 2)).to eq('0.00')
        expect(described_class.dump(Monies.new(1, 5, currency), scale: 2)).to eq('0.00')
        expect(described_class.dump(Monies.new(66, 3, currency), scale: 2)).to eq('0.06')
        expect(described_class.dump(Monies.new(1234, 3, currency), scale: 2)).to eq('1.23')
      end
    end

    context 'with separator argument' do
      it 'includes the separator' do
        expect(described_class.dump(Monies.new(123, 2, currency), separator: ' ')).to eq('1 23')
      end
    end

    context 'with thousands_separator argument' do
      it 'includes thousand separators' do
        expect(described_class.dump(Monies.new(1011000, 0, currency), thousands_separator: ',')).to eq('1,011,000')
      end
    end
  end

  describe '.load' do
    it 'returns a monies object' do
      expect(described_class.load('0', currency)).to eq(Monies.new(0, 0, currency))
      expect(described_class.load('1', currency)).to eq(Monies.new(1, 0, currency))
      expect(described_class.load('0.00', currency)).to eq(Monies.new(0, 0, currency))
      expect(described_class.load('1.00', currency)).to eq(Monies.new(1, 0, currency))
      expect(described_class.load('0.12', currency)).to eq(Monies.new(12, 2, currency))
      expect(described_class.load('1.23', currency)).to eq(Monies.new(123, 2, currency))
      expect(described_class.load('0.00001', currency)).to eq(Monies.new(1, 5, currency))
      expect(described_class.load('0.066', currency)).to eq(Monies.new(66, 3, currency))
      expect(described_class.load('1.99', currency)).to eq(Monies.new(199, 2, currency))
      expect(described_class.load('-1.99', currency)).to eq(Monies.new(-199, 2, currency))
      expect(described_class.load('-1.23', currency)).to eq(Monies.new(-123, 2, currency))
      expect(described_class.load('-0.11', currency)).to eq(Monies.new(-11, 2, currency))
      expect(described_class.load('-0.00001', currency)).to eq(Monies.new(-1, 5, currency))
    end
  end
end
