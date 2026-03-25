# frozen_string_literal: true

RSpec.describe Phonomenal::Client do
  let(:client) { Phonomenal::Client.for_campaign("test_campaign_key") }
  let(:account_client) { Phonomenal::Client.for_account("test_account_key") }

  it "has a version number" do
    expect(Phonomenal::VERSION).not_to be nil
  end

  describe "initialization" do
    it "raises when both keys are provided" do
      expect { Phonomenal::Client.new(campaign_key: "a", account_key: "b") }
        .to raise_error(ArgumentError)
    end

    it "raises when no key is provided" do
      expect { Phonomenal::Client.new }.to raise_error(ArgumentError)
    end
  end

  describe "factory methods" do
    it ".for_campaign returns a client in campaign context" do
      c = Phonomenal::Client.for_campaign("key")
      expect(c.campaign_context?).to eq(true)
      expect(c.campaign_key).to eq("key")
    end

    it ".for_account returns a client in account context" do
      c = Phonomenal::Client.for_account("key")
      expect(c.account_context?).to eq(true)
      expect(c.account_key).to eq("key")
    end

    it ".with_campaign yields a campaign context client" do
      Phonomenal::Client.with_campaign("key") do |c|
        expect(c.campaign_context?).to eq(true)
      end
    end

    it ".with_account yields an account context client" do
      Phonomenal::Client.with_account("key") do |c|
        expect(c.account_context?).to eq(true)
      end
    end
  end

  describe "context isolation" do
    it "campaign client does not respond to campaigns" do
      expect(client).not_to respond_to(:campaigns)
    end

    it "account client does not respond to campaign-specific methods" do
      %w[campaign sessions members calls sip_configs leads].each do |method|
        expect(account_client).not_to respond_to(method)
      end
    end

    it "two clients do not share methods across contexts" do
      expect(client).to respond_to(:campaign)
      expect(account_client).not_to respond_to(:campaign)

      expect(account_client).to respond_to(:campaigns)
      expect(client).not_to respond_to(:campaigns)
    end
  end

  describe "campaign context" do
    it "implements all campaign resources" do
      %w[sessions members calls sip_configs campaign leads].each do |met|
        expect(client).to respond_to(met)
      end

      expect(client.black_list_phones).to be_truthy
      expect(client.black_list_phones).to eq(client.black_list_phones)
    end

    it "sends campaign key header" do
      expect(client.headers["X-Phonomenal-Campaign-Key"]).to eq("test_campaign_key")
      expect(client.headers).not_to have_key("X-Phonomenal-Account-Key")
    end
  end

  describe "account context" do
    it "implements campaigns resource" do
      expect(account_client).to respond_to(:campaigns)
    end

    it "sends account key header" do
      expect(account_client.headers["X-Phonomenal-Account-Key"]).to eq("test_account_key")
      expect(account_client.headers).not_to have_key("X-Phonomenal-Campaign-Key")
    end

    it "lists campaigns" do
      stub_request(:get, "https://phonomenal.voizworks.com/api/v1/campaigns")
        .to_return(status: 200, body: { success: true, campaigns: [{ id: 1, name: "Test" }] }.to_json)

      response = account_client.campaigns.list
      expect(response.success?).to eq(true)
    end
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
