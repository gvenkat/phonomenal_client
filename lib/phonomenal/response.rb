# frozen_string_literal: true

module Phonomenal
  Response = Struct.new(:http_response) do
    def json
      http_response.parsed_response
    end

    def success?
      http_response.code == 200 && http_response.parsed_response["success"]
    end

    def method_missing(method, *args, **kwargs, &block)
      return http_response.send(method, *args, **kwargs, &block) if http_response.respond_to?(method)

      super
    end

    def respond_to_missing?(method, include_private = false)
      http_response.respond_to?(method, include_private) || super
    end
  end
end
