# frozen_string_literal: true

module Phonomenal
  Response = Struct.new(:http_response) do
    def json
      http_response.parsed_response
    end

    def success?
      http_response.code == 200 && http_response.parsed_response["success"]
    end

    def method_messing(method, *args, **kwargs)
      return http_response.send(method, *args, **kwargs) if http_response.respond_to?(method)

      super
    end
  end
end
