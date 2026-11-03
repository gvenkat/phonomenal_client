# frozen_string_literal: true

module Phonomenal
  # An endpoint that answers with audio rather than JSON (voice message audio
  # and previews). On success `body` is the file's bytes; on failure `json` has
  # the server's error.
  AudioResponse = Struct.new(:http_response) do
    def success?
      http_response.code == 200 && content_type.to_s.start_with?("audio/")
    end

    def body
      http_response.body
    end

    def content_type
      http_response.headers["content-type"].to_s.split(";").first
    end

    # The text the audio reads, for previews
    def text
      value = http_response.headers["x-voice-message-text"]
      value && URI.decode_www_form_component(value)
    end

    def json
      JSON.parse(body.to_s)
    rescue JSON::ParserError
      {}
    end
  end
end
