# frozen_string_literal: true

module Phonomenal
  # :nodoc:
  module CampaignContext
    def campaign
      @campaign ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "campaign",
        allowed_methods: %i[show update],
        singular: true
      ).tap do |handler|
        handler.add_method!(method_name: :clear_webhooks, method: :delete, url_path: "webhooks")
        handler.extend(CampaignVoiceMessageAudio)
        handler.extend(CampaignIvr)
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

    %w[member_groups member_tags black_list_phones holidays inbound_schedule_entries voice_messages].each do |method|
      define_method method do # rubocop:disable Metrics/MethodLength
        handler = instance_variable_get(:"@#{method}")
        unless handler
          handler = Phonomenal::ApiHandler.new(
            client: self,
            path: method,
            allowed_methods: %i[index create update show destroy],
            singular: false
          )
          handler.extend(VoiceMessageAudio) if method == "voice_messages"
          instance_variable_set(:"@#{method}", handler)
        end
        handler
      end
    end

    # The audio of a campaign's voice messages
    module VoiceMessageAudio
      # The generated audio: the message, or a sample read with its default
      # values when it's personalized. Fails (404) until it's generated.
      def audio(id)
        Phonomenal::AudioResponse.new(client.get(url_for("#{path}/#{id}/audio"), format: :plain))
      end

      # The message read for one lead: lead is a hash of full_name, email,
      # phone, language and custom_data ({ "EMI" => "Rs. 500" }). Missing
      # values fall back to the message's defaults.
      def preview(id, lead: {})
        Phonomenal::AudioResponse.new(client.post(url_for("#{path}/#{id}/preview"), body: { lead: lead }.to_json,
                                                                                    format: :plain))
      end
    end

    # The audio of the campaign's own voice message: what automated calls fall
    # back to without a matching or default voice message
    module CampaignVoiceMessageAudio
      # Its generated audio (a sample with default values when personalized).
      # Fails (404) until it's generated.
      def voice_message_audio
        Phonomenal::AudioResponse.new(client.get(url_for("#{path}/voice_message_audio"), format: :plain))
      end

      # The message read for one lead, as voice_messages.preview
      def voice_message_preview(lead: {})
        url = url_for("#{path}/voice_message_preview")
        Phonomenal::AudioResponse.new(client.post(url, body: { lead: lead }.to_json, format: :plain))
      end
    end

    # The campaign's IVR menu tree: whether it plays, its welcome message, the
    # main menu's options and sub menus, down to sub sub menus. In a sub menu
    # callers press * for the previous menu and 0 for the main menu.
    module CampaignIvr
      # The tree, under "ivr": play_ivr_menu, welcome_message, custom_audio,
      # taken_digits (the main menu's member group and tag digits), options
      # and menus
      def ivr
        Phonomenal::Response.new(client.get(url_for("#{path}/ivr")))
      end

      # Replaces the whole tree. options: [{ digit:, member_tag_id: } or
      # { digit:, member_group_id: }]; menus: [{ digit:, label:, message:,
      # options: [...], menus: [...] }]. play_ivr_menu and welcome_message
      # are optional. Nothing changes if any of it is invalid (422, with
      # "errors" naming the menu).
      def update_ivr(ivr)
        Phonomenal::Response.new(client.put(url_for("#{path}/ivr"), body: { ivr: ivr }.to_json))
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
