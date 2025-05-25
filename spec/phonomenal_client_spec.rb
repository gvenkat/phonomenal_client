# frozen_string_literal: true

RSpec.describe Phonomenal::Client do
  let(:client) { Phonomenal::Client.new(campaign_key: "test_api_key") }

  it "has a version number" do
    expect(Phonomenal::VERSION).not_to be nil
  end

  it "Implements all session methods" do
    expect(client.sessions).to respond_to(:list)
  end
end
