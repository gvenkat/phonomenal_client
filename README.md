# Phonomenal Client

A Ruby client library for the Phonomenal API by Voiz Works. Provides a clean interface for managing campaigns, sessions, members, calls, leads, SIP configurations, voice messages, and reference data (languages/voices).

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

### Request bodies and root keys

Most resources are thin wrappers around Rails controllers that call `params.require(:some_key)`,
so the hash you pass to `create`/`update` must be wrapped under that key — the client does **not**
add it for you. `leads` is the one exception: its `create`/`update` methods wrap the hash in `lead:`
internally, so you pass the fields directly. Each section below shows the exact shape expected.

## Campaign Context

Use `Phonomenal::Client.for_campaign` to operate within a specific campaign.

### Campaign

```ruby
# Show campaign details
client.campaign.show

# Update campaign (body must be wrapped in `campaign:`)
client.campaign.update({ campaign: { name: "New Name" } })

# Clear all webhooks
client.campaign.clear_webhooks
```

`campaign` update accepts any of the following keys (all optional):

| Key | Type | Notes |
|---|---|---|
| `name` | string | |
| `campaign_type` | string | one of `outbound`, `inbound`, `blended`, `streaming`, `predictive`, `automated_calling` |
| `retry_count` | integer | 0–8 |
| `dial_member_into_conference` | boolean | |
| `streaming_url` | string | must be a valid `ws://`/`wss://` URL |
| `outbound_start_url` | string | |
| `outbound_connect_url` | string | |
| `outbound_disconnect_url` | string | |
| `outbound_disposed_url` | string | |
| `outbound_end_url` | string | |
| `inbound_start_url` | string | |
| `inbound_connect_url` | string | |
| `inbound_disconnect_url` | string | |
| `inbound_disposed_url` | string | |
| `inbound_end_url` | string | |
| `leg_1_connect_url` | string | |
| `leg_1_failed_url` | string | |
| `leg_2_connect_url` | string | |
| `leg_2_failed_url` | string | |
| `member_conference_join_url` | string | |
| `member_conference_leave_url` | string | |
| `member_status_webhook_url` | string | |
| `allow_inbound` | boolean | |
| `route_inbound_to_number` | string | `+91XXXXXXXXXX` format |
| `play_ivr_menu` | boolean | |
| `ivr_welcome_message` | string | |
| `voice_message_requires_input` | boolean | whether the automated voice message waits for a DTMF response |
| `user_inputs` | string | digit-to-disposition mapping, one per line: `1 = Confirm` |
| `pacing_ratio` | decimal | 1–5 |
| `predictive_max_retries` | integer | 1–100 |
| `paused` | boolean | |
| `use_sticky_agents` | boolean | |
| `use_fresh_rnr_ratio` | boolean | |
| `fresh_lead_priority` | decimal | 0.0–1.0 |

`client.campaign.show` and `client.campaign.update` both target `/api/v1/campaign` under the
campaign key currently in use.

### Sessions

```ruby
# List active sessions
client.sessions.list

# Create/reuse a session for a member (top-level fields, no root key)
client.sessions.create({ username: "1001", password: "secret" })
# or, using an extension explicitly:
client.sessions.create({ extension: "1001", password: "secret" })

# Delete (end) a session
client.sessions.destroy(session_id)

# Session actions
client.sessions.start_break(session_id)
client.sessions.end_break(session_id)
client.sessions.switch_to_manual(session_id)
client.sessions.switch_to_auto(session_id)

# Dispose the member's current call
client.sessions.dispose_call(session_id, {
  disposition: "sale",
  sub_disposition: "confirmed",
  follow_up_at: "2026-04-01T10:00:00Z" # optional
})
```

`create` looks up the member by `username`/`extension` + `password` and returns their existing
active session if one is already open, otherwise creates a new one.

> **Note:** `client.sessions.update(session_id, { ... })` exists on the client but the server's
> `SessionsController#update` does not currently look up or modify the session — it's a no-op.
> Don't rely on it to change session state.

### Members

```ruby
client.members.list
client.members.show(member_id)
client.members.create({ member: { full_name: "Agent Name", email: "agent@example.com", phone: "1234567890", password: "secret", member_group_id: 3 } })
client.members.update(member_id, { member: { full_name: "New Name" } })
client.members.activate(member_id)
client.members.deactivate(member_id)
```

`member` accepts `full_name`, `email`, `phone`, `password`, `member_group_id`. `extension` is
assigned automatically and cannot be set.

### SIP Configurations

```ruby
client.sip_configs.list
client.sip_configs.show(sip_config_id)
client.sip_configs.create({ sip_config: { host: "sip.example.com", username: "user", password: "pass", did: "1234567890", use_did_as_user: false, dial_prefix: "0" } })
client.sip_configs.update(sip_config_id, { sip_config: { host: "sip2.example.com" } })
client.sip_configs.destroy(sip_config_id)
client.sip_configs.activate(sip_config_id)
client.sip_configs.deactivate(sip_config_id)

# Borrow a free global DID and turn it into a SIP config for this campaign.
# Note the explicit `nil` — `borrow` is a collection action, not a member action,
# so the first positional argument (normally an id) must be left blank.
client.sip_configs.borrow
client.sip_configs.borrow(nil, { did: "0791234567" }) # borrow a specific DID
```

`sip_config` accepts `host`, `username`, `password`, `did`, `use_did_as_user`, `dial_prefix`.
`update` is rejected with an error if the SIP config was borrowed from the global DID pool.

### Global DIDs

```ruby
client.global_dids.list
client.global_dids.list(start_with: "079")
client.global_dids.list(end_with: "99")
```

Lists free (unborrowed, non-retired) DIDs. Both filters are optional and can be combined.

### Member Groups

```ruby
client.member_groups.list
client.member_groups.show(group_id)
client.member_groups.create({ member_group: { label: "Team A", digit: 1 } })
client.member_groups.update(group_id, { member_group: { label: "Team B" } })
client.member_groups.destroy(group_id)
```

`member_group` accepts `label` (unique per campaign) and `digit` (the IVR keypad digit routed to
this group, unique per campaign).

> **Note:** as currently implemented server-side, `MemberGroupsController#create` saves the
> record against the campaign's *members* association instead of its *member_groups* association,
> so `create` will error against a real server. `update`/`destroy`/`index`/`show` are unaffected.

### Blacklist Phones

```ruby
client.black_list_phones.list
client.black_list_phones.show(id)
client.black_list_phones.create({ black_list_phone: { phone: "1234567890", reason: "Repeated complaints" } })
client.black_list_phones.update(id, { black_list_phone: { reason: "Updated reason" } })
client.black_list_phones.destroy(id)
```

`black_list_phone` accepts `phone` (unique per campaign) and `reason`.

### Holidays

```ruby
client.holidays.list
client.holidays.show(holiday_id)
client.holidays.create({ holiday: { year: 2026, holiday_date: "2026-01-01", reason: "New Year" } })
client.holidays.update(holiday_id, { holiday: { reason: "Updated reason" } })
client.holidays.destroy(holiday_id)
```

`holiday` accepts `year`, `holiday_date` (unique per campaign), `reason`.

### Inbound Schedule Entries

```ruby
client.inbound_schedule_entries.list
client.inbound_schedule_entries.show(entry_id)
client.inbound_schedule_entries.create({ inbound_schedule_entry: { day: "monday", start_hour: 9, start_minutes: 0, end_hour: 18, end_minutes: 0, is_holiday: false } })
client.inbound_schedule_entries.update(entry_id, { inbound_schedule_entry: { end_hour: 20 } })
client.inbound_schedule_entries.destroy(entry_id)
```

`inbound_schedule_entry` accepts:

| Key | Type | Notes |
|---|---|---|
| `day` | string | one of `global`, `sunday`, `monday`, `tuesday`, `wednesday`, `thursday`, `friday`, `saturday`; unique per campaign |
| `start_hour` | integer | |
| `start_minutes` | integer | |
| `end_hour` | integer | |
| `end_minutes` | integer | |
| `is_holiday` | boolean | marks this entry as covering holiday hours |

### Voice Messages

Per-language automated voice messages for a campaign (`is_default` marks the fallback message
used when a lead's language doesn't match any configured message; setting it unsets any other
default for the same campaign).

```ruby
client.voice_messages.list
client.voice_messages.create({ voice_message: { language_name: "en", message_text: "Hello, this is a reminder.", is_default: true } })
client.voice_messages.update(voice_message_id, { voice_message: { message_text: "Updated message." } })
```

`voice_message` accepts:

| Key | Type | Notes |
|---|---|---|
| `language_name` | string | ISO 639-1 code (see [Languages](#languages)), required |
| `message_text` | string | required; supports `{{lead_field}}` personalization tokens |
| `is_default` | boolean | |

> **Note:** the client also exposes `client.voice_messages.show(id)` and
> `client.voice_messages.destroy(id)`, but the server currently only routes
> `index`/`create`/`update` for this resource — `show` and `destroy` will 404.

### Calls

```ruby
# Create a call
client.calls.create({
  to: "1234567890",
  from: "0987654321",        # only used when there's no session context
  start_url: "https://example.com/start",
  connect_url: "https://example.com/connect",
  disconnect_url: "https://example.com/disconnect",
  end_url: "https://example.com/end",
  timeout: 30,
  custom_id: "external-ref-123"
})

# Create a call within a specific session (dials the member's softphone/conference instead)
client.calls.create({ to: "1234567890" }, session_id: 42)
```

All body fields are optional except `to`. When `session_id` is passed, the call is placed to the
member's extension (or into the conference, if the campaign has
`dial_member_into_conference` set) rather than to `from`.

### Leads

```ruby
# List leads (supports pagination and filtering)
client.leads.list
client.leads.list(filter: "blocked")   # one of: blocked, follow_up, bumped

# Create and update (fields are passed directly; the client wraps them in `lead:` for you)
client.leads.create({ full_name: "Jane Doe", phone: "1234567890", custom_unique_reference: "ext-1", email: "jane@example.com", custom_data: { plan: "gold" } })
client.leads.update(lead_id, { full_name: "Jane Smith" })

# State changes
client.leads.block(lead_id)
client.leads.unblock(lead_id)
client.leads.bump(lead_id)
client.leads.unbump(lead_id)
client.leads.unset_follow_up(lead_id)

# Assignment and scheduling
client.leads.assign(lead_id, "agent@example.com")
client.leads.unassign(lead_id)
client.leads.set_follow_up(lead_id, "2026-04-01T10:00:00Z")
```

`lead` accepts `custom_unique_reference`, `full_name`, `email`, `phone`, `member_email`,
`follow_up_at`, `custom_data` (a free-form hash).

> **Note:** the client's `unblock`, `reset`, and `set_follow_up` methods currently POST to
> `/leads/:id/unblock`, `/leads/:id/reset`, and `/leads/:id/set_follow_up` respectively. The
> server's actual routes for these are `restore` (unblock a lead) and `follow_up` (set the
> follow-up date) — there is no `reset` route at all. As shipped, `unblock`/`reset`/`set_follow_up`
> will 404 against the real server; only `restore` and `follow_up` work server-side. Use with
> caution until the client and server are reconciled.
>
> The server also exposes bulk endpoints (`POST /leads/bulk/create`, `PATCH /leads/bulk/update`,
> `DELETE /leads/bulk/remove`) that the client does not currently wrap.

## Account Context

Use `Phonomenal::Client.for_account` to manage resources at the account level.

### Campaigns

```ruby
client.campaigns.list
client.campaigns.show(campaign_id)
client.campaigns.create({ campaign: { name: "New Campaign", campaign_type: "outbound" } })
client.campaigns.update(campaign_id, { campaign: { name: "Updated Name" } })
client.campaigns.destroy(campaign_id)
```

`campaign` accepts the same fields as [Campaign](#campaign) above, plus `name` and
`campaign_type` are required on `create`.

> The server also supports `POST /campaigns/:id/activate` and `.../deactivate`, but the client
> doesn't currently expose `activate`/`deactivate` for the account-level `campaigns` resource
> (unlike `members` and `sip_configs`, which do).

### Languages

```ruby
client.languages.list
```

Read-only reference list of all supported languages (no parameters). Each entry has:

| Key | Notes |
|---|---|
| `iso_639_1` | 2-letter code, e.g. `"en"` — this is the value to use for `language_name` on voice messages |
| `iso_639_2` | 3-letter code |
| `name` | English name, e.g. `"English"` |
| `native_name` | Name in the language itself |
| `family` | Language family, e.g. `"Indo-European"` |
| `label` | Same as `name`; kept for display convenience |

### Voices

```ruby
client.voices.list
```

Read-only reference list of available text-to-speech voices (no parameters). Each entry has:

| Key | Notes |
|---|---|
| `id` | Opaque identifier (`locale:gender:name`) usable wherever a voice id is expected |
| `name` | Voice name, e.g. `"Neerja"` |
| `gender` | `"Male"` or `"Female"` |
| `locale` | e.g. `"en-IN"` |
| `short_name` | Azure short name, e.g. `"en-IN-NeerjaNeural"` |
| `label` | Human-readable summary, e.g. `"Neerja (Female, en-IN)"` |

## Response Object

All API calls return a `Phonomenal::Response` object.

```ruby
response = client.sessions.list

# Access parsed JSON body
response.json

# Check if request succeeded (HTTP 200 and success: true in body)
response.success?

# Access the underlying HTTParty response for anything else (status code, headers, etc.)
response.http_response
response.http_response.code
response.http_response.headers
```

> **Note:** `Phonomenal::Response` attempts to delegate unknown methods (like `.code` or
> `.headers` called directly on the response) to `http_response` via `method_missing`, but the
> method is currently misspelled (`method_messing`), so that delegation never fires. Call
> `.http_response.code` / `.http_response.headers` explicitly, as shown above, rather than
> `.code` / `.headers` directly on the response.

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
