require 'spec_helper'

describe AtalogicsApi do
  it 'has a version number' do
    expect(AtalogicsApi::VERSION).not_to be nil
  end

  describe described_class::Errors do
    it "returns all errors" do
      expect(described_class::ALL.length).to eq(4)
    end
  end
end
