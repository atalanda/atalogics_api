module AtalogicsApi
  module HttpartySetup
    def setup_httparty
      self.class.headers 'Accept' => 'application/json'
      self.class.headers 'Content-Type' => 'application/json'
    end
  end
end
