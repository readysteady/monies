require 'spec_helper'

describe Marshal do
  let(:subject) { Monies.new(199, 2, 'GBP') }

  it 'serializes and deserializes instances' do
    result = Marshal.dump(subject)

    expect(result).to be_a(String)

    result = Marshal.load(result)

    expect(result).to eq(subject)
  end
end
