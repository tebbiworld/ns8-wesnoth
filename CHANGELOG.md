# Changelog

## 1.1.0 — 2026-09-19

Alignment with the NethServer module conventions (NethServer/agents skills).

### Changed

- **Secrets moved out of the module environment.** The server admin password is now kept in `state/passwords.env` (mode 0600) instead of `state/environment`, which NS8 mirrors to Redis in plain text. Existing installations are migrated on update; the value does not change.
- The module backup includes `state/passwords.env`; restore reads the password from it (backups taken with 1.0.0 are still restorable).
- `update-module` only restarts a running instance.

### Added

- Robot Framework tests (install, update from the previous release, backup and restore) run on real NS8 nodes through `stephdl/ns8-ci-actions`.

### Platform integration

- **Clone and move.** New `clone-module` step (a link to the restore step): a cloned or moved instance gets its route and settings back instead of coming up unconfigured.
- Release notes are linked from the software centre (`relnotes_url`).

## 1.0.0 — 2026-09-16

- Initial release: `wesnothd` (Battle for Wesnoth 1.18.8) built server-only
  from the official source tag; game port published and opened on the node
  firewall; settings page (port, admin password, MOTD, connections per IP,
  accepted client versions, replays, disallowed nicknames, log detail);
  server console through the wesnothd FIFO (settings page and `run-command`
  action); backup of settings, config and data volume; restore; settings UI
  (EN/DE); automatic upstream-update releases from the Wesnoth git tags.
