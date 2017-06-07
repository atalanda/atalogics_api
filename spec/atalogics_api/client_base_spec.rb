require 'spec_helper'

describe AtalogicsApi::ClientBase do
  before do
    dummy_configuration
  end

  it 'throws an NotImplementedError' do
    expect { described_class.new }.to raise_error NotImplementedError
  end
end
