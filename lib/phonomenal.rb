# frozen_string_literal: true

require "httparty"
require_relative "phonomenal/version"
require_relative "phonomenal/api_handler"
require_relative "phonomenal/calls"
require_relative "phonomenal/leads"

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

    def url_for(partial_path)
      "#{base_url}/api/v1/#{partial_path}"
    end

    def campaign
      @campaign ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "campaign",
        allowed_methods: %i[show update],
        singular: true
      )
    end

    def sessions # rubocop:disable Metrics/MethodLength
      unless @sessions
        @sessions = Phonomenal::ApiHandler.new(
          client: self,
          path: "sessions",
          allowed_methods: %i[index create update destroy],
          singular: false
        )

        @sessions.add_method!(method_name: :start_break, method: :post)
        @sessions.add_method!(method_name: :end_break, method: :post)
        @sessions.add_method!(method_name: :dispose_call, method: :post)
      end

      @sessions
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

    %w[member_groups black_list_phones holidays inbound_schedule_entries].each do |method|
      define_method method do # rubocop:disable Metrics/MethodLength
        handler = instance_variable_get(:"@#{method}")

        unless handler
          handler = Phonomenal::ApiHandler.new(
            client: self,
            path: method,
            allowed_methods: %i[index create update show destroy],
            singular: false
          )
          instance_variable_set(:"@#{method}", handler)
        end

        handler
      end
    end

    def calls
      @calls ||= Phonomenal::Calls.new(self)
    end

    def leads
      @leads ||= Phonomenal::Leads.new(self)
    end
  end
end
