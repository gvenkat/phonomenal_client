# frozen_string_literal: true

module Phonomenal
  Leads = Struct.new(:client) do
    def list(filter: nil)
      Response.new(client.class.get(client.url_for("/leads"), query: { filter: filter }))
    end

    def make_response(method, path, **kwargs)
      Response.new(client.send(method, client.url_for(path), **kwargs))
    end

    def create(object)
      make_response :post, "/leads", body: { lead: object }
    end

    def update(lead_id, object)
      make_response :put, "/leads/#{lead_id}", body: { lead: object }
    end

    %w[block unblock bump unbump reset unset_follow_up].each do |method_name|
      define_method method_name do |lead_id|
        make_response :post, "/leads/#{lead_id}/#{method_name}", body: {}
      end
    end

    def set_follow_up(lead_id, follow_up_at)
      make_response :post, "/leads/#{lead_id}/set_follow_up", body: { follow_up_at: follow_up_at }
    end
  end
end
