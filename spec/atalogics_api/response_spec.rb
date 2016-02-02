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
