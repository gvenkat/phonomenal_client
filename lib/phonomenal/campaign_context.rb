# frozen_string_literal: true

module Phonomenal
  module CampaignContext
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
