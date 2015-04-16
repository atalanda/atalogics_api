module AtalogicsApi
  class Client
    include HTTParty
    include HttpartySetup

    def initialize
      setup_httparty
    end
  end
end
