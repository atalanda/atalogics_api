require 'spec_helper'

describe AtalogicsApi::V3::OfferKey, '#self.decode' do
  it 'decodes an offer key' do
    sep = described_class::SEPERATOR
    key = Base64.strict_encode64 "2017-06-08" + sep + "TIMESLOT123" + sep + "2017-06-08" + sep + "TIMESLOT456"
    expect(described_class.decode(key)).to eq({
      catch_date: "2017-06-08",
      catch_timeslot_id: "TIMESLOT123",
      drop_date: "2017-06-08",
      drop_timeslot_id: "TIMESLOT456",
    })
  end
end
