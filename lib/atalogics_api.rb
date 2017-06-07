require 'httparty'
require 'json'
require 'atalogics_api/version'
require 'atalogics_api/config'
require 'atalogics_api/shared_helpers'
require 'atalogics_api/auth'
require 'atalogics_api/response'
require 'atalogics_api/client_base'
require 'atalogics_api/v2/client'
require 'atalogics_api/v3/client'
require 'atalogics_api/v3/offer_key'

# Global Module for every sub classes
#
# @author Hubert Hoelzl
module AtalogicsApi
  class Errors
    class AccessTokenAndTokenTypeMustBeSet < StandardError; end
    class AuthenticationFailed < StandardError; end
    class ApiError < StandardError; end
  end
end
