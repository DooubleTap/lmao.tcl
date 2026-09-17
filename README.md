# lmao.tcl

**Channel management for eggdrop, built for UnderNet.**

[![Version](https://img.shields.io/badge/version-6.2.0-blue.svg)](https://github.com/DooubleTap/lmao.tcl)
[![Eggdrop](https://img.shields.io/badge/eggdrop-1.8%2B-green.svg)](https://www.eggheads.org/)
[![Tcl](https://img.shields.io/badge/tcl-8.5%2B-orange.svg)](https://www.tcl.tk/)
[![License](https://img.shields.io/badge/license-GPLv3-lightgrey.svg)](LICENSE)

One script that gives your eggdrop the public commands people actually expect in a
channel — ops, bans, topic, user management — plus an auto-voice system for regulars
and idle cleanup for ops and voices. Every reply comes back as a **notice**, so the
bot never floods your channel.

---

## Highlights

- **No channel spam.** Every command reply is a notice to the user who asked. The bot
  only speaks in the channel when you explicitly tell it to (`!say`, `!act`, `!global`).
- **One help table.** `!help` and `/msg <bot> help` share a single source of truth, so
  documentation can't drift away from the commands.
- **Per-channel modules.** Turn features on and off per channel with `!enable` /
  `!disable`, without touching the config or reloading anything.
- **Self-registration.** `/msg <bot> register` adds someone to the userfile behind a
  typed-back confirmation code, re-checks every condition before saving, and tells them to
  auth with X and set `+x` first so a hidden host gets stored instead of an ISP one.
- **One audit trail.** The `chanlog` module sends access changes, sanctions, registrations,
  denied attempts and bot control to an ops channel of your choosing, per channel.
- **ActiveVoice.** Voices people who actually talk, and takes it back when they go idle.
  Registered regulars (`+n`, `+m`, `+v`) are never touched.
- **Flag protection.** `+n` and `+m` users and service bots (`X`, `W`) can't be
  deopped, devoiced, kicked or banned by the bot.
- **UnderNet aware.** Written against ircu behaviour and the `X` service.

---

## Install

```sh
cd ~/eggdrop/scripts
wget https://raw.githubusercontent.com/DooubleTap/lmao.tcl/master/lmao.tcl
```

Add it to your `eggdrop.conf`:

```tcl
source scripts/lmao.tcl
```

Then `.rehash` on the partyline. You should see:

```
[lmao.tcl 6.2.0] - Complete production ready version
Loaded successfully - ready to serve!
```

---

## Configure

Everything lives in the `CONFIGURATION SECTION` at the top of the script.

| Setting | Default | What it does |
| --- | --- | --- |
| `cc(cmdchar)` | `!` | Command trigger character |
| `cc(mainchan)` | `#mainchan` | Main public channel |
| `cc(backchan)` | `#secretchan` | Ops channel that `!ops` alerts |
| `cc(backmode)` | `+s` | Modes for the back channel |
| `cc(idledeop_default_hours)` | `3` | Hours before an idle op is deopped |
| `cc(idledeop_check_interval)` | `300` | Seconds between idle-deop sweeps |
| `cc(activevoice_idle_hours)` | `3` | Hours before an idle voice is removed |
| `cc(activevoice_check_interval)` | `300` | Seconds between devoice sweeps |
| `cc(activevoice_exempt_flags)` | `n m v` | Flags that make a user invisible to ActiveVoice |
| `cc(protected_bots)` | `X W` | Nicks the bot will never deop |
| `cc(protected_flags)` | `n m` | Flags that protect a user from deop/devoice |

---

## Modules

Modules are per channel and all default to **on**. Change them in the channel you want
to change, or by `/msg` naming the channel.

| Module | What it does |
| --- | --- |
| `topic` | `!topic` / `!topicsync` — stores the topic and re-applies it when it drifts |
| `activevoice` | Auto-voices non-registered users when they talk, and tracks their activity |
| `idledevoice` | Removes voice from non-registered users who have gone idle |
| `idledeop` | Deops ops who have been idle past the channel's limit |
| `chanlog` | Sends the channel's audit trail to the ops channel |

```
!module list                          show every module and its state here
!enable activevoice                   turn one on for this channel
!disable idledevoice                  turn one off for this channel
/msg <bot> disable #chan idledevoice   same thing, privately
```

## Registering users

People can add themselves:

```
/msg <bot> register [handle]      -> the bot shows what it would store and sends a code
/msg <bot> verify <code>          -> it re-checks everything, then registers
```

The code has to be read out of a notice and typed back, which stops scripted bulk
registration. Nothing is written until it comes back, and every check runs a second time at
that point — shares a channel, host unchanged, host not already owned, handle still free,
code not expired. A new registration gets **no access flags**; ops grant those with
`!chattr`.

Host-based identification is only as good as the host, so the bot says so every time:
auth with X and set `+x` first, and it stores `<account>.users.undernet.org` — a host only
that X account can wear — instead of an ISP host that gets recycled to a stranger.

```tcl
set cc(register_enabled) 1      ;# master switch
set cc(register_token_life) 300 ;# seconds a code stays valid
set cc(register_cooldown) 600   ;# seconds between attempts from one host
set cc(register_handle_max) 9   ;# must not exceed handlen in eggdrop.conf
set cc(register_flags) ""       ;# flags a registration grants - leave empty
```

## Channel logging

```
!chanlog                 where does this channel log, and is it on
!chanlog #ops            send the log there and switch it on
!chanlog off             stop logging this channel
/msg <bot> chanlog #chan #ops
```

```
[ACCESS]   #canada boss opped newguy
[SANCTION] #canada boss banned troll (*!*@troll.host) - spam
[REGISTER] newguy registered as newguy (*!*@dsl-1-2-3.videotron.ca)
[MODULE]   #canada boss disabled module idledevoice
[BOT]      boss reloaded the scripts (rehash)
[DENIED]   troll (*) tried restart by /msg
```

Refused attempts are logged too — that is usually the part worth reading. Automatic voice
and devoice are left out on purpose; they would bury everything else.

> **Note:** module states and chanlog destinations are held in memory. A `.rehash` or
> `.restart` puts every module back to its default and every log back to `cc(backchan)`.

---

## Commands

Help is always a notice. `!help` on its own lists the categories; `!help <command>`
gives you usage, description and an example.

### Everyone

| Command | Description |
| --- | --- |
| `!help [command]` | Command help, always by notice |
| `!showcommands` | Every command name in one list |
| `!verify [nick]` | Access level, flags and registered hosts |
| `/msg <bot> register` | Register yourself — the bot sends a code to type back |
| `!version` | Version and repository link |

### Registered users

| Command | Description |
| --- | --- |
| `!bot` | Trigger character and support channel |
| `!info [text\|none]` | Set, show or clear your infoline |
| `!whois <nick>` | A user's access level and flags |
| `!ops <reason>` | Alert the ops in the back channel |

### Ops — `+o`

| Command | Description |
| --- | --- |
| `!op [nick]` | Give op |
| `!deop [nick]` | Take op (never `+n`/`+m` users or service bots) |
| `!voice [nick]` | Give voice |
| `!devoice [nick]` | Take voice (never `+n`/`+m` users) |
| `!invite <nick>` | Invite someone in |
| `!kick <nick> [reason]` | Kick |
| `!ban <nick> [reason]` | Kick and ban (`*!*@host`) |
| `!unban <mask>` | Remove a ban |
| `!bans` | List the channel's bans |
| `!topic <text>` | Set and store the topic |
| `!topicsync` | Re-apply the stored topic |

### Masters — `+m`

| Command | Description |
| --- | --- |
| `!mode <modes>` | Set channel modes |
| `!blacklist <nick> [reason]` | Permanent ban |
| `!whitelist <mask>` | Remove from the blacklist |
| `!chattr <handle> <+\|-flags>` | Change a user's flags on this channel |
| `!adduser <handle> [mask]` | Add a user to the bot |
| `!deluser <handle>` | Remove a user |
| `!say <text>` | Speak in the channel |
| `!act <text>` | Action in the channel |
| `!idledeop <#chan> [hours]` | Set the idle-deop limit |
| `!module`, `!enable`, `!disable` | Module control |
| `!chanlog [#chan|on|off]` | Where this channel's audit trail goes |

### Owner — `+n`

| Command | Description |
| --- | --- |
| `!join <#chan>` / `!part <#chan>` | Join or leave, updating the channel list |
| `!comeback` | Part and rejoin here |
| `!botnick <nick>` | Change the bot's nick |
| `!away <msg>` / `!back` | Set or clear the away message |
| `!global <text>` | Message every channel |
| `!rehash` / `!restart` | Reload scripts / restart the bot |
| `!jump` | Jump to another server |
| `!save` | Write the userfile and channel file |
| `!chanset <+\|->setting` | Toggle `youtube`, `weather`, `needhelp`, `isup` |
| `!uptime` | How long the bot has been up |

### By private message

Anything that needs a channel takes it as the first argument. Access is checked on the
channel you name, so channel-only ops and masters work too.

```
/msg <bot> help [command]
/msg <bot> showcommands
/msg <bot> verify [nick]
/msg <bot> op #chan [nick]
/msg <bot> module #chan list
/msg <bot> enable #chan <module>
/msg <bot> disable #chan <module>
/msg <bot> rehash | restart | jump | save
```

---

## How ActiveVoice works

1. Someone who is **not** a registered `+n`/`+m`/`+v` user talks in the channel.
2. The bot voices them and starts their activity clock.
3. If they stop talking for `activevoice_idle_hours`, the `idledevoice` sweep takes
   the voice back.

Registered regulars are skipped completely — the bot never touches voice they already
have. Service bots and ops are skipped too. Anyone already voiced when the script
loads gets their clock started on the first sweep rather than being devoiced.

Don't want the devoicing? `!disable idledevoice` — auto-voicing keeps working.

---

## Requirements

- eggdrop 1.8 or newer (tested on 1.10.1)
- Tcl 8.5 or newer
- The bot needs op in the channels it manages

---

## License

GPLv3 — see [LICENSE](LICENSE).
