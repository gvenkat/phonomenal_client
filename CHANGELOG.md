## [Unreleased]

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
