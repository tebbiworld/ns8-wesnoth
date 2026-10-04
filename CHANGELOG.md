# Changelog

## 1.1.2 — unreleased

Platform integration. These changes were reviewed in PR #2 but merged into a
side branch instead of `main`, so 1.1.0 and 1.1.1 shipped without them.

### Added

- **Clone and move.** New `clone-module` step (a link to the restore step): a cloned or moved instance gets its route and settings back instead of coming up unconfigured. The settings are read from the source instance, including those a new instance starts with a default for.
- Release notes are linked from the software centre (`relnotes_url`).

## 1.1.1 — 2026-09-23

Maintenance release without changes to the module: the registry clean-up
workflow now uses the token that actually exists. No update needed.

## 1.1.0 — 2026-09-19

Alignment with the NethServer module conventions (NethServer/agents skills).

### Changed

- **Secrets moved out of the module environment.** The server admin password is now kept in `state/passwords.env` (mode 0600) instead of `state/environment`, which NS8 mirrors to Redis in plain text. Existing installations are migrated on update; the value does not change.
- The module backup includes `state/passwords.env`; restore reads the password from it (backups taken with 1.0.0 are still restorable).
- `update-module` only restarts a running instance.

### Added

- Robot Framework tests (install, update from the previous release, backup and restore) run on real NS8 nodes through `stephdl/ns8-ci-actions`.

## 1.0.0 — 2026-09-16

- Initial release: `wesnothd` (Battle for Wesnoth 1.18.8) built server-only
  from the official source tag; game port published and opened on the node
  firewall; settings page (port, admin password, MOTD, connections per IP,
  accepted client versions, replays, disallowed nicknames, log detail);
  server console through the wesnothd FIFO (settings page and `run-command`
  action); backup of settings, config and data volume; restore; settings UI
  (EN/DE); automatic upstream-update releases from the Wesnoth git tags.
