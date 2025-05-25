# frozen_string_literal: true

require_relative "phonomenal_client/version"
require_relative "phonomenal_client/api_handler"

module Phonomenal
  class Error < StandardError; end

  class Client
    include HTTParty

    DEFAULT_BASE_URL = 'https://phonomenal.voizworks.com'

    format :json

    attr_reader :base_url, :campaign_key

    def initialize(base_url: nil, campaign_key:)
      @base_url = base_url || DEFAULT_BASE_URL
      @campaign_key = campaign_key

      self.class.base_uri base_url

      self.headers 'Content-Type' => 'application/json'
      self.class.headers 'X-Phonomenal-Campaign-Key' => campaign_key
    end

    def campaign
    end

    def sessions
      @sessions ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "api/v1/sessions",
        allowed_methods: [:index, :create, :update, :destroy]
        singular: false
      )
    end

    def sip_configs
      @sip_configs ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "api/v1/sip_configs",
        allowed_methods: [:index, :create, :update, :destroy, :activate, :deactivate, :show]
        singular: false
      )
    end

    def members
      @members ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "api/v1/members",
        allowed_methods: [:index, :create, :update, :activate, :deactivate, :show]
        singular: false
      )
    end

    def calls
      @calls ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "api/v1/calls",
        allowed_methods: [:create]
        singular: false
      )
    end
  end
end
