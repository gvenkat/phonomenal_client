# Phonomenal Client

A Ruby client library for the Phonomenal API by Voiz Works. Provides a clean interface for managing campaigns, sessions, members, calls, leads, and SIP configurations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'phonomenal_client'
```

Then run:

```
bundle install
```

## Quick Start

The client operates in one of two contexts: campaign or account. You must choose one when initializing.

```ruby
# Campaign context
client = Phonomenal::Client.for_campaign("your_campaign_key")

# Account context
client = Phonomenal::Client.for_account("your_account_key")
```

## Authentication

All requests are authenticated via request headers:

- Campaign context: `X-Phonomenal-Campaign-Key`
- Account context: `X-Phonomenal-Account-Key`

## Configuration

### Base URL

The default base URL is `https://phonomenal.voizworks.com`. You can override it:

```ruby
client = Phonomenal::Client.for_campaign("key", base_url: "https://staging.example.com")
```

### Block Syntax

Both factory methods have a `with_*` variant that yields the client to a block:

```ruby
Phonomenal::Client.with_campaign("key") do |client|
  client.sessions.list
end

Phonomenal::Client.with_account("key") do |client|
  client.campaigns.list
end
```

## Campaign Context

Use `Phonomenal::Client.for_campaign` to operate within a specific campaign.

### Campaign

```ruby
# Show campaign details
client.campaign.show

# Update campaign
client.campaign.update({ campaign: { name: "New Name" } })

# Clear all webhooks
client.campaign.clear_webhooks
```

### Sessions

```ruby
# List sessions (supports query params)
client.sessions.list
client.sessions.list(status: "active")

# Create a session
client.sessions.create({ agent_email: "agent@example.com" })

# Update a session
client.sessions.update(session_id, { status: "inactive" })

# Delete a session
client.sessions.destroy(session_id)

# Session actions
client.sessions.start_break(session_id)
client.sessions.end_break(session_id)
client.sessions.dispose_call(session_id)
client.sessions.switch_to_manual(session_id)
client.sessions.switch_to_auto(session_id)
```

### Members

```ruby
client.members.list
client.members.show(member_id)
client.members.create({ email: "agent@example.com", name: "Agent Name" })
client.members.update(member_id, { name: "New Name" })
client.members.activate(member_id)
client.members.deactivate(member_id)
```

### SIP Configurations

```ruby
client.sip_configs.list
client.sip_configs.show(sip_config_id)
client.sip_configs.create({ ... })
client.sip_configs.update(sip_config_id, { ... })
client.sip_configs.destroy(sip_config_id)
client.sip_configs.activate(sip_config_id)
client.sip_configs.deactivate(sip_config_id)

# Borrow a SIP configuration from another source
client.sip_configs.borrow
```

### Global DIDs

```ruby
client.global_dids.list
client.global_dids.list(start_with: "079")
```

### Member Groups

```ruby
client.member_groups.list
client.member_groups.show(group_id)
client.member_groups.create({ name: "Team A" })
client.member_groups.update(group_id, { name: "Team B" })
client.member_groups.destroy(group_id)
```

### Blacklist Phones

```ruby
client.black_list_phones.list
client.black_list_phones.show(id)
client.black_list_phones.create({ phone: "1234567890" })
client.black_list_phones.update(id, { ... })
client.black_list_phones.destroy(id)
```

### Holidays

```ruby
client.holidays.list
client.holidays.show(holiday_id)
client.holidays.create({ name: "Holiday", date: "2026-01-01" })
client.holidays.update(holiday_id, { ... })
client.holidays.destroy(holiday_id)
```

### Inbound Schedule Entries

```ruby
client.inbound_schedule_entries.list
client.inbound_schedule_entries.show(entry_id)
client.inbound_schedule_entries.create({ ... })
client.inbound_schedule_entries.update(entry_id, { ... })
client.inbound_schedule_entries.destroy(entry_id)
```

### Calls

```ruby
# Create a call
client.calls.create({ phone: "1234567890" })

# Create a call within a specific session
client.calls.create({ phone: "1234567890" }, session_id: 42)
```

### Leads

```ruby
# List leads
client.leads.list
client.leads.list(filter: "active")

# Create and update
client.leads.create({ name: "Jane Doe", phone: "1234567890" })
client.leads.update(lead_id, { name: "Jane Smith" })

# State changes
client.leads.block(lead_id)
client.leads.unblock(lead_id)
client.leads.bump(lead_id)
client.leads.unbump(lead_id)
client.leads.reset(lead_id)
client.leads.unset_follow_up(lead_id)

# Assignment and scheduling
client.leads.assign(lead_id, "agent@example.com")
client.leads.unassign(lead_id)
client.leads.set_follow_up(lead_id, "2026-04-01T10:00:00Z")
```

## Account Context

Use `Phonomenal::Client.for_account` to manage resources at the account level.

### Campaigns

```ruby
client.campaigns.list
client.campaigns.show(campaign_id)
client.campaigns.create({ name: "New Campaign" })
client.campaigns.update(campaign_id, { name: "Updated Name" })
client.campaigns.destroy(campaign_id)
```

## Response Object

All API calls return a `Phonomenal::Response` object.

```ruby
response = client.sessions.list

# Access parsed JSON body
response.json

# Check if request succeeded (HTTP 200 and success: true in body)
response.success?

# Access underlying HTTParty response
response.http_response
response.code
response.headers
```

## Error Handling

```ruby
begin
  client = Phonomenal::Client.new(campaign_key: "a", account_key: "b")
rescue ArgumentError => e
  puts e.message  # "Provide either campaign_key or account_key, not both"
end

response = client.leads.create({ ... })
unless response.success?
  puts "Request failed: #{response.json}"
end
```

## Requirements

- Ruby >= 3.0.0
- [httparty](https://github.com/jnunemaker/httparty)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
