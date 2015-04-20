require 'spec_helper'

describe AtalogicsApi::SharedHelpers do
  class Dummy
    include HTTParty
    include AtalogicsApi::SharedHelpers
  end

  describe "add_json_header" do
    it "should call httparty methods to add json headers" do
      dummy = Dummy.new
      expect(dummy.class).to receive(:headers).with('Accept' => 'application/json')
      expect(dummy.class).to receive(:headers).with('Content-Type' => 'application/json')
      dummy.add_json_header
    end
  end

  describe "raise_if_error" do
    shared_examples 'raise_errors' do
      it "should raise an error, if response.code==401" do
        response = double("response", code: code, body: "Foobar")
        dummy = Dummy.new
        expect {
          dummy.raise_if_error(response)
        }.to raise_error error_class, /#{response.body}/
      end
    end

    context '401' do
      let(:code) { 401 }
      let(:error_class) { AtalogicsApi::Errors::AuthenticationFailed }
      it_behaves_like 'raise_errors'
    end

    context '403' do
      let(:code) { 403 }
      let(:error_class) { AtalogicsApi::Errors::AuthenticationFailed }
      it_behaves_like 'raise_errors'
    end

    context '500' do
      let(:code) { 500 }
      let(:error_class) { AtalogicsApi::Errors::ApiError }
      it_behaves_like 'raise_errors'
    end

    it 'should not raise an error with a 400 status' do
      response = double("response", code: 400, body: "Foobar")
      dummy = Dummy.new
      expect {
        dummy.raise_if_error(response)
      }.not_to raise_error
    end

  end
end
