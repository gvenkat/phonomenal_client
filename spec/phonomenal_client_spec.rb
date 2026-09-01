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
    it "implements language listing" do
      expect(account_client).to respond_to(:languages)
    end

    it "implements voices listing" do
      expect(account_client).to respond_to(:voices)
    end
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
    %w[sessions members calls sip_configs campaign leads voice_messages].each do |met|
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

  describe "leads" do
    # Note the doubled slash: `url_for` joins "/api/v1/" with a leading-slash path.
    # Rails normalises it away, so these are the URLs actually requested.
    let(:base) { "https://phonomenal.voizworks.com/api/v1//leads" }

    def stub_lead_post(path, body: nil)
      stub = stub_request(:post, "#{base}/#{path}")
      stub = stub.with(body: body) unless body.nil?
      stub.to_return(status: 200, body: { success: true, lead: { id: 1 } }.to_json)
    end

    it "bumps a lead with no schedule" do
      request = stub_lead_post("1/bump", body: {}.to_json)

      expect(client.leads.bump(1).success?).to eq(true)
      expect(request).to have_been_requested
    end

    it "bumps a lead with a scheduled time" do
      request = stub_lead_post("1/bump", body: { bump_at: "2026-09-01 18:30:00" }.to_json)

      expect(client.leads.bump(1, bump_at: "2026-09-01 18:30:00").success?).to eq(true)
      expect(request).to have_been_requested
    end

    it "unbumps a lead" do
      request = stub_lead_post("1/unbump", body: {}.to_json)

      expect(client.leads.unbump(1).success?).to eq(true)
      expect(request).to have_been_requested
    end

    it "posts state changes to the routes the server actually exposes" do
      %w[block restore unbump unset_follow_up].each do |action|
        request = stub_lead_post("1/#{action}")

        client.leads.public_send(action, 1)
        expect(request).to have_been_requested
      end
    end

    it "sends unblock to the restore route" do
      request = stub_lead_post("1/restore")

      expect(client.leads.unblock(1).success?).to eq(true)
      expect(request).to have_been_requested
    end

    it "sends set_follow_up to the follow_up route" do
      request = stub_lead_post("1/follow_up", body: { follow_up_at: "2026-09-01 18:30:00" }.to_json)

      expect(client.leads.set_follow_up(1, "2026-09-01 18:30:00").success?).to eq(true)
      expect(request).to have_been_requested
    end

    it "assigns and unassigns a lead" do
      assignment = stub_lead_post("1/assign", body: { member_email: "agent@example.com" }.to_json)
      removal    = stub_lead_post("1/unassign", body: {}.to_json)

      client.leads.assign(1, "agent@example.com")
      client.leads.unassign(1)

      expect(assignment).to have_been_requested
      expect(removal).to have_been_requested
    end

    it "no longer exposes reset, which has no route on the server" do
      expect(client.leads).not_to respond_to(:reset)
    end
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
