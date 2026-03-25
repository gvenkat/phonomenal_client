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

    expect(client.black_list_phones).to be_truthy
    expect(client.black_list_phones).to eq(client.black_list_phones)
  end

  it "allows user to borrow a did" do
    stub_request(:post, "https://phonomenal.voizworks.com/api/v1/sip_configs/borrow")
      .to_return(status: 200, body: { success: true, sip_config: { did: "9980333099" } }.to_json)

    response = client.sip_configs.borrow

    expect(response.success?).to eq(true)
  end

  it "has a method to remove all webhooks from campaign" do
    stub_request(:delete, "https://phonomenal.voizworks.com/api/v1/campaign/webhooks")
      .to_return(status: 200, body: { success: true, sessions: [{ token: "blah", started: "blah" }] }.to_json)

    expect(client.campaign).to respond_to(:clear_webhooks)
    expect { client.campaign.clear_webhooks }.not_to raise_error
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

  it "searches global dids" do
    stub_request(:get, "https://phonomenal.voizworks.com/api/v1/global_dids")
      .to_return(status: 200, body: { success: true, global_dids: [{ did: "0802332332222" }] }.to_json)

    stub_request(:get, "https://phonomenal.voizworks.com/api/v1/global_dids?start_with=079")
      .to_return(status: 200, body: { success: true, global_dids: [] }.to_json)

    response = client.global_dids.list
    expect(response.success?).to eq(true)

    response = client.global_dids.list(start_with: "079")
    expect(response.success?).to eq(true)
    expect(response.json["global_dids"]).to eq([])
  end
end
