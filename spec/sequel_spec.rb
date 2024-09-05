require 'spec_helper'
require 'sequel'

describe Sequel do
  let(:monies) { Monies.new(123, 2, currency) }
  let(:currency) { 'GBP' }
  let(:instance) { @model.first }

  before :all do
    @database = if RUBY_ENGINE == 'jruby'
      Sequel.connect('jdbc:sqlite::memory:')
    else
      Sequel.connect('sqlite:/')
    end

    @dataset = @database[:products]

    Sequel::Model.cache_anonymous_models = false
  end

  after :all do
    @database.disconnect
  end

  before :each do
    @dataset.delete
  end

  context 'Model with string column' do
    before :context do
      @database.create_table!(:products) do
        primary_key :id
        String :price
      end

      @model = Sequel::Model(:products)
      @model.plugin(Monies::Serialization::Sequel)
      @model.serialize_monies(:price)
    end

    describe '.where' do
      it 'serializes a monies value' do
        expect(@model.where(price: monies).sql).to include(%{WHERE (`price` = '1.23 GBP')})
      end

      it 'serializes nil' do
        expect(@model.where(price: nil).sql).to include(%{WHERE (`price` IS NULL)})
      end
    end

    describe '.create' do
      it 'serializes a monies value' do
        @model.create(price: monies)

        expect(@dataset.get(:price)).to eq('1.23 GBP')
      end

      it 'serializes nil' do
        @model.create(price: nil)

        expect(@dataset.get(:price)).to be_nil
      end
    end

    describe '#update' do
      it 'serializes a monies value' do
        @dataset.insert

        instance.update(price: monies)

        expect(@dataset.get(:price)).to eq('1.23 GBP')
      end

      it 'serializes nil' do
        @dataset.insert(price: '1.23 GBP')

        instance.update(price: nil)

        expect(@dataset.get(:price)).to be_nil
      end
    end

    describe '#attribute' do
      it 'returns a monies value' do
        @dataset.insert(price: '1.23 GBP')

        expect(instance.price).to eq(monies)
      end
    end
  end

  context 'Model with string column and currency string' do
    before :context do
      @database.create_table!(:products) do
        primary_key :id
        String :price
      end

      @model = Sequel::Model(:products)
      @model.plugin(Monies::Serialization::Sequel)
      @model.serialize_monies(:price, currency: 'GBP')
    end

    describe '.where' do
      it 'serializes a monies value' do
        expect(@model.where(price: monies).sql).to include(%{WHERE (`price` = '1.23')})
      end

      it 'serializes nil' do
        expect(@model.where(price: nil).sql).to include(%{WHERE (`price` IS NULL)})
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          expect { @model.where(price: monies).sql }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '.create' do
      it 'serializes a monies value' do
        @model.create(price: monies)

        expect(@dataset.get(:price)).to eq('1.23')
      end

      it 'serializes nil' do
        @model.create(price: nil)

        expect(@dataset.get(:price)).to be_nil
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          expect { @model.create(price: monies) }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '#update' do
      it 'serializes a monies value' do
        @dataset.insert

        instance.update(price: monies)

        expect(@dataset.get(:price)).to eq('1.23')
      end

      it 'serializes nil' do
        @dataset.insert(price: '1.23')

        instance.update(price: nil)

        expect(@dataset.get(:price)).to be_nil
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          @dataset.insert

          expect { instance.update(price: monies) }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '#attribute' do
      it 'returns a monies value' do
        @dataset.insert(price: '1.23')

        expect(instance.price).to eq(monies)
      end
    end
  end

  context 'Model with decimal column and currency string' do
    before :context do
      @database.create_table!(:products) do
        primary_key :id
        BigDecimal :price
      end

      @model = Sequel::Model(:products)
      @model.plugin :dirty
      @model.plugin(Monies::Serialization::Sequel)
      @model.serialize_monies(:price, currency: 'GBP')
    end

    describe '.where' do
      it 'serializes a monies value' do
        expect(@model.where(price: monies).sql).to include(%{WHERE (`price` = 1.23)})
      end

      it 'serializes nil' do
        expect(@model.where(price: nil).sql).to include(%{WHERE (`price` IS NULL)})
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          expect { @model.where(price: monies).sql }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '.create' do
      it 'serializes a monies value' do
        @model.create(price: monies)

        expect(@dataset.get(:price)).to eq(BigDecimal('1.23'))
      end

      it 'serializes nil' do
        @model.create(price: nil)

        expect(@dataset.get(:price)).to be_nil
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          expect { @model.create(price: monies) }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '#update' do
      it 'serializes a monies value' do
        @dataset.insert

        instance.update(price: monies)

        expect(@dataset.get(:price)).to eq(BigDecimal('1.23'))
      end

      it 'serializes nil' do
        @dataset.insert(price: BigDecimal('1.23'))

        instance.update(price: nil)

        expect(@dataset.get(:price)).to be_nil
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          @dataset.insert

          expect { instance.update(price: monies) }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '#attribute' do
      it 'returns a monies value' do
        @dataset.insert(price: BigDecimal('1.23'))

        expect(instance.price).to eq(monies)
      end
    end
  end

  context 'Model with decimal column and currency column' do
    before :context do
      @database.create_table!(:products) do
        primary_key :id
        BigDecimal :price
        String :currency
      end

      @model = Sequel::Model(:products)
      @model.plugin(Monies::Serialization::Sequel)
      @model.serialize_monies(:price, currency: :currency)
    end

    describe '.where' do
      it 'serializes a monies value and currency' do
        expect(@model.where(price: monies).sql).to include(%{WHERE (`price` = 1.23 AND `currency` = 'GBP')})
      end

      it 'serializes nil' do
        expect(@model.where(price: nil).sql).to include(%{WHERE (`price` IS NULL)})
      end
    end

    describe '.create' do
      it 'serializes a monies value' do
        @model.create(price: monies)

        expect(@dataset.get(:price)).to eq(BigDecimal('1.23'))
        expect(@dataset.get(:currency)).to eq(currency)
      end

      it 'serializes nil' do
        @model.create(price: nil)

        expect(@dataset.get(:price)).to be_nil
        expect(@dataset.get(:currency)).to be_nil
      end
    end

    describe '#update' do
      it 'serializes a monies value' do
        @dataset.insert

        instance.update(price: monies)

        expect(@dataset.get(:price)).to eq(BigDecimal('1.23'))
        expect(@dataset.get(:currency)).to eq(currency)
      end

      it 'serializes nil' do
        @dataset.insert(price: BigDecimal('1.23'), currency: currency)

        instance.update(price: nil)

        expect(@dataset.get(:price)).to be_nil
        expect(@dataset.get(:currency)).to be_nil
      end
    end

    describe '#attribute' do
      it 'returns a monies value' do
        @dataset.insert(price: BigDecimal('1.23'), currency: currency)

        expect(instance.price).to eq(monies)
      end
    end
  end
end
