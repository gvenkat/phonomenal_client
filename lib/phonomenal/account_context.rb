# frozen_string_literal: true

module Phonomenal
  module AccountContext
    def campaigns
      @campaigns ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "campaigns",
        allowed_methods: %i[index create update destroy show],
        singular: false
      )
    end
  end
end
