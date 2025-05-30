# frozen_string_literal: true

module Phonomenal
  Calls = Struct.new(:client) do
    def create(body, session_id: nil)
      url = session_id.nil? ? client.url_for("/calls") : client.url_for("/sessions/#{session_id}/calls")
      Phonomenal::Response.new(client.class.post(url, body: body.to_json))
    end
  end
end
