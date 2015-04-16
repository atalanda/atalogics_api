module AtalogicsApi
  class MissingConfiguration < StandardError; end
  class MissingClientId < StandardError; end
  class MissingClientSecret < StandardError; end

  # PRODUCTION_BASE_URL = "https://beta.atalogics.com"
  PRODUCTION_BASE_URL = "http://localhost:3000"
  SANDBOX_BASE_URL = "https://sandbox.atalogics.com"
  API_URL = "/api/v2"

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

    def api_url
      valid_config?
      "#{base_url}#{API_URL}"
    end

    def base_url
      valid_config?
      config.sandbox_mode ? SANDBOX_BASE_URL : PRODUCTION_BASE_URL
    end

    private
    def valid_config?
      raise MissingConfiguration if !config
      raise MissingClientId if !config.client_id || config.client_id==""
      raise MissingClientSecret if !config.client_secret || config.client_secret==""
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
    attr_accessor :client_id, :client_secret, :sandbox_mode
    def initialize
      @sandbox_mode = false
    end
  end
end
