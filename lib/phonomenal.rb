# frozen_string_literal: true

require "httparty"
require_relative "phonomenal/version"
require_relative "phonomenal/api_handler"
require_relative "phonomenal/calls"
require_relative "phonomenal/leads"
require_relative "phonomenal/campaign_context"
require_relative "phonomenal/account_context"

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
      raise ArgumentError, "Provide either campaign_key or account_key, not both" if campaign_key && account_key
      raise ArgumentError, "Either campaign_key or account_key is required" unless campaign_key || account_key

      @base_url = base_url || DEFAULT_BASE_URL
      @campaign_key = campaign_key
      @account_key = account_key
      extend(campaign_context? ? Phonomenal::CampaignContext : Phonomenal::AccountContext)
    end

    def campaign_context?
      !@campaign_key.nil?
    end

    def account_context?
      !@account_key.nil?
    end

    def headers
      key_header =
        if campaign_context?
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
  end
end
