# frozen_string_literal: true

module Phonomenal
  # :nodoc:
  module AccountContext
    def campaigns
      @campaigns ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "campaigns",
        allowed_methods: %i[index create update destroy show],
        singular: false
      )
    end

    def languages
      @languages ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "languages",
        allowed_methods: %i[index],
        singular: false
      )
    end

    def voices
      @voices ||= Phonomenal::ApiHandler.new(
        client: self,
        path: "voices",
        allowed_methods: %i[index],
        singular: false
      )
    end
  end
end
