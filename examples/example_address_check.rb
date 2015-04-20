lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'atalogics_api'

AtalogicsApi.configure do |config|
  config.client_id = "XXXXXXXXXXXXXXXXXXXXXXXXX"
  config.client_secret = "XXXXXXXXXXXXXXXXXXXXXXXXX"
end

# generate a new client
client = AtalogicsApi::Client.new
access_token = client.access_token
puts "access_token: #{access_token}"

# refresh your access token
access_token = client.refresh_access_token
puts "new access_token: #{access_token}"

puts "-----------------------------------"

# address_check, response is an instance of HTTParty::Response
response = client.address_check street: "Ignaz Harrer Str. 12", postal_code: 5020, city: "Salzburg"
puts "address_check response:"
puts "Code: #{response.code}, parsed_response: #{response.parsed_response}"

puts "-----------------------------------"

# information about the catch and drop address
catch_drop_information = {
  catch_address: {
    street: "Ignaz Harrer Str. 12", postal_code: 5020, city: "Salzburg"
  },
  drop_address: {
    street: "Nonntaler Haupstr. 114", postal_code: 5020, city: "Salzburg"
  }
}
# get offers
offers = client.offers catch_drop_information
puts "offers response:"
puts offers
offer_id = offers.first["offer_id"]

puts "-----------------------------------"

# purchase an offer
catch_drop_information = {
  offer_id: offer_id,
  catch_address: {
    name: "Jane Doe",
    phone: "1234567890",
    street: "Ignaz Harrer Str. 12", postal_code: 5020, city: "Salzburg"
  },
  drop_address: {
    name: "John Doe",
    phone: "1234567890",
    street: "Nonntaler Haupstr. 114", postal_code: 5020, city: "Salzburg"
  }
}
shipment = client.purchase_offer catch_drop_information
puts "purchased shipment response:"
puts shipment
