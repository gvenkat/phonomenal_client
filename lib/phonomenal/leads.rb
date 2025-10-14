# frozen_string_literal: true

module Phonomenal
  Leads = Struct.new(:client) do
    def list(filter: nil)
      Response.new(client.class.get(client.url_for("/leads"), query: { filter: filter }))
    end

    def create
    end

    def update
    end

    def block
    end

    def restore
    end

    def bump
    end

    def unbump
    end

    def set_follow_up
    end

    def unset_follow_up
    end

    def reset
    end

    def bulk_create
    end

    def bulk_delete
    end
  end
end
