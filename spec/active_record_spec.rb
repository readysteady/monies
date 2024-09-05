require 'spec_helper'
require 'active_record'

describe ActiveRecord, skip: (RUBY_ENGINE == 'jruby') do
  let(:monies) { Monies.new(123, 2, currency) }
  let(:currency) { 'GBP' }
  let(:instance) { @model.first }

  before :each do
    @model.delete_all
  end

  def select_price
    @model.connection.select_value(@model.arel_table.project(:price))
  end

  def select_currency
    @model.connection.select_value(@model.arel_table.project(:currency))
  end

  def create_table(name, &block)
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

    ActiveRecord::Schema.define(version: 1) do
      ActiveRecord::Migration.suppress_messages do
        create_table(name, force: true, &block)
      end
    end
  end

  context 'Model with string column' do
    before :context do
      create_table :widgets do |t|
        t.string :price
      end

      @model = Class.new(ActiveRecord::Base)
      @model.table_name = :widgets
      @model.include Monies::Serialization::ActiveRecord
      @model.serialize_monies(:price)
    end

    describe '.where' do
      it 'serializes a monies value' do
        expect(@model.where(price: monies).to_sql).to include(%{WHERE "widgets"."price" = '1.23 GBP'})
      end

      it 'serializes nil' do
        expect(@model.where(price: nil).to_sql).to include(%{WHERE "widgets"."price" IS NULL})
      end
    end

    describe '.create!' do
      it 'serializes a monies value' do
        @model.create!(price: monies)

        expect(select_price).to eq('1.23 GBP')
      end

      it 'serializes nil' do
        @model.create!(price: nil)

        expect(select_price).to be_nil
      end
    end

    describe '#update!' do
      it 'serializes a monies value' do
        @model.connection.insert('INSERT INTO widgets (price) VALUES (NULL)')

        instance.update!(price: monies)

        expect(select_price).to eq('1.23 GBP')
      end

      it 'serializes nil' do
        @model.connection.insert('INSERT INTO widgets (price) VALUES ("1.23 GBP")')

        instance.update!(price: nil)

        expect(select_price).to be_nil
      end
    end

    describe '#attribute' do
      it 'returns a monies value' do
        @model.connection.insert('INSERT INTO widgets (price) VALUES ("1.23 GBP")')

        expect(instance.price).to eq(monies)
      end
    end
  end

  context 'Model with string column and currency string' do
    before :context do
      create_table :widgets do |t|
        t.string :price
      end

      @model = Class.new(ActiveRecord::Base)
      @model.table_name = :widgets
      @model.include Monies::Serialization::ActiveRecord
      @model.serialize_monies(:price, currency: 'GBP')
    end

    describe '.where' do
      it 'serializes a monies value' do
        expect(@model.where(price: monies).to_sql).to include(%{WHERE "widgets"."price" = '1.23'})
      end

      it 'serializes nil' do
        expect(@model.where(price: nil).to_sql).to include(%{WHERE "widgets"."price" IS NULL})
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          expect { @model.where(price: monies).to_sql }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '.create!' do
      it 'serializes a monies value' do
        @model.create!(price: monies)

        expect(select_price).to eq('1.23')
      end

      it 'serializes nil' do
        @model.create!(price: nil)

        expect(select_price).to be_nil
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          expect { @model.create!(price: monies) }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '#update!' do
      it 'serializes a monies value' do
        @model.connection.insert(%{INSERT INTO widgets (`price`) VALUES (NULL)})

        instance.update!(price: monies)

        expect(select_price).to eq('1.23')
      end

      it 'serializes nil' do
        @model.connection.insert(%{INSERT INTO widgets (`price`) VALUES ('1.23')})

        instance.update!(price: nil)

        expect(select_price).to be_nil
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          @model.connection.insert(%{INSERT INTO widgets (`price`) VALUES (NULL)})

          expect { instance.update!(price: monies) }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '#attribute' do
      it 'returns a monies value' do
        @model.connection.insert(%{INSERT INTO widgets (`price`) VALUES ('1.23')})

        expect(instance.price).to eq(monies)
      end
    end
  end

  context 'Model with decimal column and currency string' do
    before :context do
      create_table :widgets do |t|
        t.decimal :price
      end

      @model = Class.new(ActiveRecord::Base)
      @model.table_name = :widgets
      @model.include Monies::Serialization::ActiveRecord
      @model.serialize_monies(:price, currency: 'GBP')
    end

    describe '.where' do
      it 'serializes a monies value' do
        expect(@model.where(price: monies).to_sql).to include(%{WHERE "widgets"."price" = 1.23})
      end

      it 'serializes nil' do
        expect(@model.where(price: nil).to_sql).to include(%{WHERE "widgets"."price" IS NULL})
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          expect { @model.where(price: monies).to_sql }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '.create!' do
      it 'serializes a monies value' do
        @model.create!(price: monies)

        expect(select_price).to eq(BigDecimal('1.23'))
      end

      it 'serializes nil' do
        @model.create!(price: nil)

        expect(select_price).to be_nil
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          expect { @model.create!(price: monies) }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '#update!' do
      it 'serializes a monies value' do
        @model.connection.insert(%{INSERT INTO widgets (`price`) VALUES (NULL)})

        instance.update!(price: monies)

        expect(select_price).to eq(BigDecimal('1.23'))
      end

      it 'serializes nil' do
        @model.connection.insert(%{INSERT INTO widgets (`price`) VALUES (1.23)})

        instance.update!(price: nil)

        expect(select_price).to be_nil
      end

      context 'when currency does not match' do
        let(:currency) { 'USD' }

        it 'raises an exception' do
          @model.connection.insert(%{INSERT INTO widgets (`price`) VALUES (NULL)})

          expect { instance.update(price: monies) }.to raise_error(Monies::CurrencyError)
        end
      end
    end

    describe '#attribute' do
      it 'returns a monies value' do
        @model.connection.insert(%{INSERT INTO widgets (`price`) VALUES (1.23)})

        expect(instance.price).to eq(monies)
      end
    end
  end

  context 'Model with decimal column and currency column' do
    before :context do
      create_table :widgets do |t|
        t.decimal :price
        t.string :currency
      end

      @model = Class.new(ActiveRecord::Base)
      @model.table_name = :widgets
      @model.include Monies::Serialization::ActiveRecord
      @model.serialize_monies(:price, currency: :currency)
    end

    describe '.where' do
      it 'serializes a monies value and currency' do
        expect(@model.where(price: monies).to_sql).to include(%{WHERE "widgets"."price" = 1.23 AND "widgets"."currency" = 'GBP'})
      end

      it 'serializes nil' do
        expect(@model.where(price: nil).to_sql).to include(%{WHERE "widgets"."price" IS NULL})
      end
    end

    describe '.create!' do
      it 'serializes a monies value' do
        @model.create!(price: monies)

        expect(select_price).to eq(BigDecimal('1.23'))
        expect(select_currency).to eq(currency)
      end

      it 'serializes nil' do
        @model.create!(price: nil)

        expect(select_price).to be_nil
        expect(select_currency).to be_nil
      end
    end

    describe '#update!' do
      it 'serializes a monies value' do
        @model.connection.insert(%{INSERT INTO widgets (`price`, `currency`) VALUES (NULL, NULL)})

        instance.update!(price: monies)

        expect(select_price).to eq(BigDecimal('1.23'))
        expect(select_currency).to eq(currency)
      end

      it 'serializes nil' do
        @model.connection.insert(%{INSERT INTO widgets (`price`, `currency`) VALUES ('1.23', 'GBP')})

        instance.update!(price: nil)

        expect(select_price).to be_nil
        expect(select_currency).to be_nil
      end
    end

    describe '#attribute' do
      it 'returns a monies value' do
        @model.connection.insert(%{INSERT INTO widgets (`price`, `currency`) VALUES ('1.23', 'GBP')})

        expect(instance.price).to eq(monies)
      end
    end
  end
end
