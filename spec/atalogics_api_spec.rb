require 'spec_helper'

describe AtalogicsApi do
  it 'has a version number' do
    expect(AtalogicsApi::VERSION).not_to be nil
  end

  describe described_class::Errors do
    it "returns all errors" do
      expect(described_class::ALL).not_to be_empty
    end
  end
end
