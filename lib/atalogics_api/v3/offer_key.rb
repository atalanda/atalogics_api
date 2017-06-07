module AtalogicsApi
  module V3
    class OfferKey
      SEPERATOR = "++".freeze
      FIELD_ORDER = [:catch_date, :catch_timeslot_id, :drop_date, :drop_timeslot_id].freeze

      def self.decode digest
        values = Base64.decode64(digest).split SEPERATOR
        Hash[*FIELD_ORDER.zip(values).flatten]
      end
    end
  end
end
