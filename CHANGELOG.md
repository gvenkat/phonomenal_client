## [Unreleased]

## [0.9.0] - 2026-11-05

### Added
- `campaign.voice_message_audio` fetches the audio of the campaign's own voice message
  (what automated calls fall back to), and `campaign.voice_message_preview(lead: {...})`
  reads it for one lead's values. Both return a `Phonomenal::AudioResponse`.
- The campaign's JSON has `voice_message_audio` (`personalized`, `audio_status`,
  `audio_error`, `audio_duration_seconds`, `audio_generated_at`), and
  `voice_message_webhook_url` also gets `event: "campaign.voice_message_audio_generated"`.

## [0.8.0] - 2026-11-03

### Added
- `voice_messages.audio(id)` fetches a voice message's generated audio (WAV), and
  `voice_messages.preview(id, lead: {...})` the message read for one lead's values. Both
  return a `Phonomenal::AudioResponse`: `success?`, `body` (the bytes), `content_type`,
  `text` (what a preview reads) and `json` (the error, on failure).
- Voice messages take a `voice_id` (from `voices.list`), and show `voice_label`,
  `personalized` and their audio's `audio_status`, `audio_error`, `audio_duration_seconds`
  and `audio_generated_at`.
- Campaigns take a `voice_message_webhook_url`, which Phonomenal POSTs to
  (`event: "voice_message.audio_generated"`) when a voice message's audio is ready or fails.

### Fixed
- Methods added with `add_method!` sent POST data as query parameters; they now send it
  as a JSON body.
- `Phonomenal::Response` now passes unknown methods (`body`, `code`, `headers`) to the
  HTTP response, as intended; the hook was misspelt.

## [0.7.0] - 2026-09-08

### Added
- `leads.unassign_all(member_email)` clears every lead held by one agent in a single call,
  hitting the new `POST /leads/unassign_all` collection route. It returns
  `unassigned_count` rather than a lead, and 404s when no member in the campaign has that
  email.

## [0.6.0] - 2026-09-01

### Added
- `leads.bump(lead_id, bump_at:)` takes an optional scheduled time. `bump_at` is when the
  lead becomes due for priority, so a future time schedules a bump rather than applying one
  immediately. Omitting it keeps the previous behaviour of bumping from now.
- `leads.restore`, matching the server route for un-blocking a lead.

### Fixed
- `leads.set_follow_up` posted to `/leads/:id/set_follow_up`, which has no route on the
  server and always 404'd. It now posts to `/leads/:id/follow_up`.
- `leads.unblock` posted to `/leads/:id/unblock`, which has no route. It is now an alias of
  `leads.restore` and reaches the server.

### Removed
- `leads.reset`. There is no `reset` route on the server, so every call 404'd.

### Notes
- Lead endpoints had no test coverage at all; they are covered now.

## [0.1.0] - 2025-05-24

- Initial release
