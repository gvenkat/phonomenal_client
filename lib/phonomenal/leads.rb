# frozen_string_literal: true

module Phonomenal
  Leads = Struct.new(:client) do
    def list(filter: nil)
      Response.new(client.get(client.url_for("/leads"), query: { filter: filter }))
    end

    def make_response(method, path, **kwargs)
      Response.new(client.send(method, client.url_for(path), **kwargs))
    end

    def create(object)
      make_response :post, "/leads", body: { lead: object }.to_json
    end

    def update(lead_id, object)
      make_response :put, "/leads/#{lead_id}", body: { lead: object }.to_json
    end

    # State changes that carry no payload. Every name here matches a `post` member
    # route on the server, so adding to this list means adding a route to match.
    %w[block restore unbump unset_follow_up].each do |method_name|
      define_method method_name do |lead_id|
        make_response :post, "/leads/#{lead_id}/#{method_name}", body: {}.to_json
      end
    end

    # Kept for callers written against the old name, which never had a route.
    alias_method :unblock, :restore

    # Move a lead to the front of the dialling queue.
    #
    # `bump_at` is when the lead becomes due for priority, not when the bump was
    # made - pass a future time to schedule one. The server bumps from now when it
    # is omitted.
    def bump(lead_id, bump_at: nil)
      body = bump_at.nil? ? {} : { bump_at: bump_at }

      make_response :post, "/leads/#{lead_id}/bump", body: body.to_json
    end

    def set_follow_up(lead_id, follow_up_at)
      make_response :post, "/leads/#{lead_id}/follow_up", body: { follow_up_at: follow_up_at }.to_json
    end

    def assign(lead_id, member_email)
      make_response :post, "/leads/#{lead_id}/assign", body: { member_email: member_email }.to_json
    end

    def unassign(lead_id)
      make_response :post, "/leads/#{lead_id}/unassign", body: {}.to_json
    end
  end
end
