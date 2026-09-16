# ns8-wesnoth

[NethServer 8](https://github.com/NethServer/ns8-core) module for a
**[Battle for Wesnoth](https://www.wesnoth.org/) multiplayer server**
(`wesnothd`), built by the module from the official source tag — a permanent
lobby for the free, open-source turn-based strategy game.

- `wesnothd` compiled server-only from the pinned Wesnoth release (no game
  data, ~170 MB image, a few dozen MB of RAM)
- Settings page: game port (default 15000), administrator password (`/query
  admin` from a client), message of the day, connections per IP, accepted
  client versions, replay saving, disallowed nicknames, log detail
- **Server console** on the settings page (wesnothd admin commands through
  the server FIFO: `status`, `games`, `msg`, `kick`, `ban`, `motd`, …), also
  as the `run-command` action for scripts
- Port published on the node and opened on the node firewall
- **Backup**: settings, server config and the data volume (replays, ban list);
  full restore
- Automatic upstream-update releases: a weekly check of the Wesnoth git tags
  (stable series only — even minor numbers) rebuilds and releases the module

Players use the normal Wesnoth client (Linux, Windows, macOS, Steam, mobile
ports): *Multiplayer → Connect to Server → `<node>:<port>`*. Client and
server must be from the same stable series (e.g. every 1.18.x client can join
a 1.18.8 server); the module accepts the whole series by default.

## Install

Add the repository `https://raw.githubusercontent.com/tebbiworld/ns8-repo/main/ns8/updates/`
in Software Center → Repositories, then install *Wesnoth Server*. Or from the
leader node:

    add-module ghcr.io/tebbiworld/wesnoth:latest 1

## Configure

Open the instance settings, check the port, set a message of the day and —
if players should be able to become admin from inside the game — an
administrator password. Save. The status tile shows the server version,
connected players and running games; the text below it is the address to
give to players.

| Setting | wesnothd key | Notes |
| --- | --- | --- |
| Game port | (`-p`, published) | TCP; opened on the node firewall as public service `<instance>` |
| Administrator password | `passwd` | Optional. `/query admin <password>` in the client lobby |
| Message of the day | `motd` | |
| Connections per IP | `connections_allowed` | 0 = unlimited; default 5 |
| Accepted client versions | `versions_accepted` | Empty = `<major>.<minor>.*` of the server; patterns with `*`/`?`, comma separated |
| Save replays | `save_replays` / `replay_save_path` | Into `wesnoth-data/replays` |
| Disallowed nicknames | `disallow_names` | Empty = wesnothd defaults |
| Log detail | `--log-<level>=server` | The console needs at least *info* |

Fixed in the generated `state/wesnothd.cfg`: `fifo_path` (console),
`ban_save_file` (persistent bans), flood limits (8 messages / 10 s),
`allow_remote_shutdown=no`, and `[ban_time]` presets `short` (1 h), `day`,
`week`, `month` for `ban <mask> <name> [reason]`.

### Console

The settings page sends wesnothd admin commands through the server's FIFO
and shows the answer. From the leader node:

    api-cli run module/wesnoth1/run-command --data '{"command":"status"}'
    runagent -m wesnoth1 wesnothd-cmd games
    runagent -m wesnoth1 wesnothd-cmd msg Server restarts in 5 minutes

`help` lists every command. Useful ones: `status [nick|ip]`, `games`,
`metrics`, `msg <text>`, `lobbymsg <text>`, `kick <mask> [reason]`,
`ban <mask> <time> [reason]`, `kickban <mask> <time> [reason]`, `unban <mask>`,
`bans`, `motd [text]`, `searchlog <mask>`.

### Players outside the LAN

Forward the game port (TCP) on the router to the node, or give players a
DNS name that points to it. Connections per IP defaults to 5 — raise it if
many players sit behind one NAT address.

## Backup and restore

The NS8 backup contains the module settings, the generated `wesnothd.cfg`
and the `wesnoth-data` volume (replays, ban list). A restore recreates the
instance, opens the port on the target node and starts the server.

## Updates

The module pins a Wesnoth source tag (`build-images.sh`). A weekly GitHub
Action lists the tags of `wesnoth/wesnoth`, and when a newer **stable**
release (even minor: 1.18.x, 1.20.x, …) is at least six weeks old it rebuilds
`wesnoth-server`, bumps the module version and publishes both images. The
Software Center update restarts the server. Note that a new series (1.18 →
1.20) means players need the new client series as well; keep the module on
the old release if your group still plays the old one (the version pattern
can also be widened in the settings, but mixed series cannot play together).

## Development

    IMAGETAG=1.0.0 bash ./build-images.sh

`server/Containerfile` builds `wesnothd` in a Debian trixie builder stage
(`cmake -DENABLE_GAME=OFF -DENABLE_SERVER=ON`) and copies the binary into a
slim runtime image running as uid 1000.

## License

Module: GPL-3.0-or-later. Battle for Wesnoth and `wesnothd` are GPL-2.0-or-later,
© the Battle for Wesnoth project; the module builds the unmodified upstream
source. The Wesnoth logo is used to identify the upstream project.
