# frozen_string_literal: true

RSpec.describe Phonomenal::Client do
  let(:client) { Phonomenal::Client.new(campaign_key: "test_api_key") }

  it "has a version number" do
    expect(Phonomenal::VERSION).not_to be nil
  end

  it "Implements all resources" do
    %w[sessions members calls sip_configs campaign leads].each do |met|
      expect(client).to respond_to(met)
    end
  end

  it "lists sessions" do
    stub_request(:get, "https://phonomenal.voizworks.com/api/v1/sessions")
      .to_return(status: 200, body: { success: true, sessions: [{ token: "blah", started: "blah" }] }.to_json)

    response = client.sessions.list

    expect(response.success?).to eq(true)
  end

  it "allows you to take a break on active session" do
    stub_request(:post, "https://phonomenal.voizworks.com/api/v1/sessions/1/start_break")
      .to_return(status: 200, body: { success: true, session: { token: "blah", started: "blah" } }.to_json)

    response = client.sessions.start_break(1)
    expect(response.success?).to eq(true)
  end

  it "gets campaign details" do
    stub_request(:any, "https://phonomenal.voizworks.com/api/v1/campaign")
      .to_return(status: 200, body: { success: true, campaign: [{ token: "blah", started: "blah" }] }.to_json)

    response = client.campaign.show
    expect(response.success?).to eq(true)

    response = client.campaign.update({ campaign: { foo: "bar" } })
    expect(response.success?).to eq(true)
  end
end
