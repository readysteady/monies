require 'spec_helper'

describe JSON do
  let(:subject) { Monies.new(199, 2, 'GBP') }

  it 'serializes instances' do
    result = JSON.generate({amount: subject})

    expect(result).to eq('{"amount":"1.99 GBP"}')
  end
end
