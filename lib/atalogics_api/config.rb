module AtalogicsApi
  class MissingConfiguration < StandardError; end
  class MissingClientId < StandardError; end
  class MissingClientSecret < StandardError; end

  PRODUCTION_BASE_URL = "https://beta.atalogics.com"
  SANDBOX_BASE_URL = "https://sandbox.atalogics.com"
  API_URL_V2 = "/api/v2"
  API_URL_V3 = "/api/v3"

  class << self
    attr_accessor :config

    def client_id
      valid_config?
      config.client_id
    end

    def client_secret
      valid_config?
      config.client_secret
    end

    def sandbox_mode
      valid_config?
      config.sandbox_mode
    end

    def api_url_v2
      valid_config?
      "#{base_url}#{API_URL_V2}"
    end

    def api_url_v3
      valid_config?
      "#{base_url}#{API_URL_V3}"
    end

    def cache_store
      valid_config?
      config.cache_store
    end

    def base_url
      valid_config?
      config.sandbox_mode ? sandbox_base_url : production_base_url
    end

    private
    def valid_config?
      raise MissingConfiguration if !config
      raise MissingClientId if !config.client_id || config.client_id==""
      raise MissingClientSecret if !config.client_secret || config.client_secret==""
    end

    def production_base_url
      config.production_base_url || PRODUCTION_BASE_URL
    end

    def sandbox_base_url
      config.sandbox_base_url || SANDBOX_BASE_URL
    end
  end

  def self.configure
    self.config ||= Config.new
    yield(config)
  end

  def self.reset
    self.config = nil
  end

  class Config
    attr_accessor :client_id, :client_secret, :sandbox_mode, :production_base_url, :sandbox_base_url, :cache_store
    def initialize
      @sandbox_mode = false
    end
  end
end
