require 'spec_helper'

describe AtalogicsApi::Response do
  it 'stores code and body' do
    code = 201
    body = {some: "values"}
    response = described_class.new code, body
    expect(response.code).to eq(code)
    expect(response.body).to eq(body)
  end
end

describe AtalogicsApi::Response, '#to_s' do
  it 'returns a String representation' do
    response = described_class.new 200, {foo: 'bar'}
    expect(response.to_s).to eq('#<AtalogicsApi::Response, code: 200, body: {:foo=>"bar"}>')
  end
end
