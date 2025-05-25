# frozen_string_literal: true

require "httparty"
require_relative "phonomenal/version"
require_relative "phonomenal/api_handler"

module Phonomenal
  class Error < StandardError; end

  class Client
    include ::HTTParty

    DEFAULT_BASE_URL = "https://phonomenal.voizworks.com"

    format :json

    attr_reader :base_url, :campaign_key

    def initialize(campaign_key:, base_url: nil)
      @base_url = base_url || DEFAULT_BASE_URL
      @campaign_key = campaign_key

      self.class.base_uri base_url

      self.class.headers "X-Phonomenal-Campaign-Key" => campaign_key, "Content-Type" => "application/json"
    end

    def campaign
    end

    def sessions
      @sessions ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "sessions",
        allowed_methods: %i[index create update destroy],
        singular: false
      )
    end

    def sip_configs
      @sip_configs ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "sip_configs",
        allowed_methods: %i[index create update destroy activate deactivate show],
        singular: false
      )
    end

    def members
      @members ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "members",
        allowed_methods: %i[index create update activate deactivate show],
        singular: false
      )
    end

    def calls
      @calls ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "calls",
        allowed_methods: [:create],
        singular: false
      )
    end
  end
end
