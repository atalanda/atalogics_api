require 'spec_helper'

describe AtalogicsApi do
  it 'should store client_id and client_secret' do
    AtalogicsApi.configure do |config|
      config.client_id = 'some_client_id'
      config.client_secret = 'some_client_secret'
    end

    expect(AtalogicsApi.client_id).to eq('some_client_id')
    expect(AtalogicsApi.client_secret).to eq('some_client_secret')
  end

  context "valid configuration" do
    before :each do
      AtalogicsApi.configure do |config|
        config.client_id = 'some_client_id'
        config.client_secret = 'some_client_secret'
      end
    end

    it "should reset the configuration" do
      AtalogicsApi.reset
      expect(AtalogicsApi.config).to be_nil
    end

    it 'should enable and disable sandbox mode' do
      expect(AtalogicsApi.sandbox_mode).to be(false)
      AtalogicsApi.configure do |config|
        config.sandbox_mode = true
      end
      expect(AtalogicsApi.sandbox_mode).to be(true)
    end

    context 'production' do
      it 'returns an production api url' do
        expect(AtalogicsApi.base_url).to eq(AtalogicsApi::PRODUCTION_BASE_URL)
        expect(AtalogicsApi.api_url).to eq("#{AtalogicsApi::PRODUCTION_BASE_URL}#{AtalogicsApi::API_URL}")
      end
    end

    context 'sandbox' do
      it 'returns an production api url' do
        AtalogicsApi.configure do |config|
          config.sandbox_mode = true
        end
        expect(AtalogicsApi.base_url).to eq(AtalogicsApi::SANDBOX_BASE_URL)
        expect(AtalogicsApi.api_url).to eq("#{AtalogicsApi::SANDBOX_BASE_URL}#{AtalogicsApi::API_URL}")
      end
    end

    context 'with cache_store' do
      it 'sets a cache store' do
        AtalogicsApi.configure do |config|
          config.cache_store = {}
        end
        expect(AtalogicsApi.cache_store).to eq({})
      end
    end
  end

  describe "errors" do
    it "should raise configuration errors" do
      expect { AtalogicsApi.client_id }.to raise_error AtalogicsApi::MissingConfiguration

      AtalogicsApi.configure do |config|
      end
      expect { AtalogicsApi.client_secret }.to raise_error AtalogicsApi::MissingClientId

      AtalogicsApi.configure do |config|
        config.client_id = ""
      end
      expect { AtalogicsApi.sandbox_mode }.to raise_error AtalogicsApi::MissingClientId

      AtalogicsApi.configure do |config|
        config.client_id = "some_client_id"
      end
      expect { AtalogicsApi.api_url }.to raise_error AtalogicsApi::MissingClientSecret

      AtalogicsApi.configure do |config|
        config.client_id = "some_client_id"
        config.client_secret = ""
      end
      expect { AtalogicsApi.base_url }.to raise_error AtalogicsApi::MissingClientSecret
    end

    it "should raise read only errors" do
      AtalogicsApi.configure do |config|
        config.client_id = "some_client_id"
        config.client_secret = "some_client_secret"
      end

      expect { AtalogicsApi.client_id = "foobar" }.to raise_error NoMethodError
      expect { AtalogicsApi.client_secret = "foobar" }.to raise_error NoMethodError
      expect { AtalogicsApi.sandbox_mode = "foobar" }.to raise_error NoMethodError
      expect { AtalogicsApi.api_url = "foobar" }.to raise_error NoMethodError
    end
  end
end
