# frozen_string_literal: true

require "httparty"
require_relative "phonomenal/version"
require_relative "phonomenal/api_handler"
require_relative "phonomenal/calls"
require_relative "phonomenal/leads"

module Phonomenal
  class Error < StandardError; end

  class Client
    DEFAULT_BASE_URL = "https://phonomenal.voizworks.com"

    def self.for_campaign(campaign_key, base_url: nil)
      new(campaign_key: campaign_key, base_url: base_url)
    end

    def self.for_account(account_key, base_url: nil)
      new(account_key: account_key, base_url: base_url)
    end

    def self.with_campaign(*args, **kwargs)
      yield for_campaign(*args, **kwargs)
    end

    def self.with_account(*args, **kwargs)
      yield for_account(*args, **kwargs)
    end

    attr_reader :base_url, :campaign_key, :account_key

    def initialize(campaign_key: nil, account_key: nil, base_url: nil)
      if campaign_key && account_key
        raise ArgumentError, "Provide either campaign_key or account_key, not both"
      end

      unless campaign_key || account_key
        raise ArgumentError, "Either campaign_key or account_key is required"
      end

      @base_url = base_url || DEFAULT_BASE_URL
      @campaign_key = campaign_key
      @account_key = account_key
    end

    def campaign_context?
      !@campaign_key.nil?
    end

    def account_context?
      !@account_key.nil?
    end

    def headers
      key_header = if campaign_context?
        { "X-Phonomenal-Campaign-Key" => campaign_key }
      else
        { "X-Phonomenal-Account-Key" => account_key }
      end

      key_header.merge("Content-Type" => "application/json")
    end

    def url_for(partial_path)
      "#{base_url}/api/v1/#{partial_path}"
    end

    # Add helper methods for HTTP requests that use instance-level config
    def get(url, options = {})
      HTTParty.get(url, default_options.merge(options))
    end

    def post(url, options = {})
      HTTParty.post(url, default_options.merge(options))
    end

    def put(url, options = {})
      HTTParty.put(url, default_options.merge(options))
    end

    def patch(url, options = {})
      HTTParty.patch(url, default_options.merge(options))
    end

    def delete(url, options = {})
      HTTParty.delete(url, default_options.merge(options))
    end

    private

    def default_options
      {
        headers: headers,
        format: :json
      }
    end

    public

    def campaign
      @campaign ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "campaign",
        allowed_methods: %i[show update],
        singular: true
      ).tap do |handler|
        handler.add_method!(method_name: :clear_webhooks, method: :delete, url_path: "webhooks")
      end
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
        @sessions.add_method!(method_name: :switch_to_manual, method: :post)
        @sessions.add_method!(method_name: :switch_to_auto, method: :post)
      end
      @sessions
    end

    def sip_configs
      unless @sip_configs
        @sip_configs = Phonomenal::ApiHandler.new(
          client: self,
          path: "sip_configs",
          allowed_methods: %i[index create update destroy activate deactivate show],
          singular: false
        )
        @sip_configs.add_method!(method_name: "borrow", method: :post)
      end

      @sip_configs
    end

    def members
      @members ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "members",
        allowed_methods: %i[index create update activate deactivate show],
        singular: false
      )
    end

    def global_dids
      @global_dids ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "global_dids",
        allowed_methods: %i[index],
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
