module AtalogicsApi
  module HttpartySetup
    def add_json_header
      self.class.headers 'Accept' => 'application/json'
      self.class.headers 'Content-Type' => 'application/json'
    end
  end
end
