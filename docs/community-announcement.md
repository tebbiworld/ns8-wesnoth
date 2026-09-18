<!--
First community post for the NS8 Battle for Wesnoth module, written in the style
of https://community.nethserver.org/t/ns8-forgejo-testing/28554 (first post).
Paste into a new topic on community.nethserver.org, category "App", tag "ns8".
Fill in the wiki link once the page is published.
-->

# NS8 Wesnoth (testing)

Hi all,

I've built an NS8 module for a [Battle for Wesnoth](https://www.wesnoth.org/) multiplayer server (`wesnothd`) — a permanent lobby for the free, open-source turn-based strategy game. The module compiles the server itself from the official Wesnoth source tag.

It's in my community repository. To try it, add the repo once:

```
api-cli run add-repository --data '{"name":"tebbiworld","url":"https://raw.githubusercontent.com/tebbiworld/ns8-repo/main/ns8/updates/","status":true,"testing":false}'
```

then install **Wesnoth Server** from the Software Center. (Or straight from the image: `add-module ghcr.io/tebbiworld/wesnoth:latest 1`.)

What it does:

* Runs `wesnothd` built server-only from the pinned Wesnoth release — small image, a few dozen MB of RAM
* Settings page for the game port, administrator password, message of the day, connections per IP, accepted client versions, replay saving, disallowed nicknames and log detail
* A **server console** on the settings page for wesnothd admin commands (`status`, `games`, `msg`, `kick`, `ban`, `motd`, …), also as a `run-command` action
* Opens the game port on the node firewall (default 15000/tcp)
* **Backup** of settings, server config and the data volume (replays, ban list), with full restore

A few things to know:

* Players use the ordinary Wesnoth client (Linux, Windows, macOS, Steam, mobile ports): *Multiplayer → Connect to Server → `<node>:<port>`*
* Client and server must share the same stable series (e.g. any 1.18.x client joins a 1.18.8 server); the module accepts the whole series by default
* A new series (1.18 → 1.20) means players need the matching client series too — keep the module on the old release if your group hasn't upgraded
* Players outside the LAN need the port forwarded on the router; raise *connections per IP* if many players sit behind one NAT address
* Still testing — works here, but more games running through it would be great

If you play Wesnoth and set up a lobby for your group, do let me know how it goes — feedback and bug reports welcome.

Docs: NethServer wiki (tebbiworld repository) · Source: [github.com/tebbiworld/ns8-wesnoth](https://github.com/tebbiworld/ns8-wesnoth)

Thanks!

*Category: App · Tags: ns8*
