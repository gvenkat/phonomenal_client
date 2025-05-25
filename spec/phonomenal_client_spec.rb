# frozen_string_literal: true

RSpec.describe Phonomenal::Client do
  let(:client) { Phonomenal::Client.new(campaign_key: "test_api_key") }

  it "has a version number" do
    expect(Phonomenal::VERSION).not_to be nil
  end

  it "Implements all resources" do
    %w[sessions members calls sip_configs campaign].each do |met|
      expect(client).to respond_to(met)
    end
  end

  it "Session login" do
    stub_request(:get, "https://phonomenal.voizworks.com/api/v1/sessions")
      .to_return(status: 200, body: { success: true, sessions: [{ token: "blah", started: "blah" }] }.to_json)

    response = client.sessions.list

    expect(response.success?).to eq(true)
  end
end
