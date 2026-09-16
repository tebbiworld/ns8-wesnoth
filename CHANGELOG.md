# Changelog

## 1.0.0 — 2026-09-16

- Initial release: `wesnothd` (Battle for Wesnoth 1.18.8) built server-only
  from the official source tag; game port published and opened on the node
  firewall; settings page (port, admin password, MOTD, connections per IP,
  accepted client versions, replays, disallowed nicknames, log detail);
  server console through the wesnothd FIFO (settings page and `run-command`
  action); backup of settings, config and data volume; restore; settings UI
  (EN/DE); automatic upstream-update releases from the Wesnoth git tags.
