# lmao.tcl

**Channel management for eggdrop, built for UnderNet.**

[![Version](https://img.shields.io/badge/version-6.4.0-blue.svg)](https://github.com/DooubleTap/lmao.tcl)
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
  only speaks in the channel when you explicitly tell it to (`!say`, `!act`, `!global`)
  — and in the ops channel, where the audit trail is a normal message everyone can read.
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
  deopped, devoiced, kicked or banned by the bot. A named exempt list covers the
  people who run the channel even when they aren't in the userfile.
- **No colour codes.** The bot never sends mIRC colours. Plain text reads the same
  in every client and on every theme.
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
[lmao.tcl 6.4.0] - Complete production ready version
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
| `cc(deop_exempt)` | `Secoupe Seb` | Nicks or handles the idle-deop sweep never touches |

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
`!addvoice`, `!addmod` and friends — see [Access levels](#access-levels).

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

The log goes out as an ordinary channel **message**, not a notice, so it lands in the
ops channel window like anything else and scrolls back normally. No colour codes: the
`[CATEGORY]` tag carries the meaning on its own.

> **Note:** module states and chanlog destinations are held in memory. A `.rehash` or
> `.restart` puts every module back to its default and every log back to `cc(backchan)`.

---

## Access levels

Access is a **position**, not a pile of flags. Every user sits on exactly one rung:

| Level | Flag | What it gets |
| --- | --- | --- |
| Owner | `+n` | Everything. Granted on DCC with `.chattr`, never by command |
| Master | `+m` | `!addop`, modes, blacklist, modules, chanlog, adduser/deluser |
| Op | `+o` | Channel `+o`, plus everything a mod can do, plus topic |
| Mod | `+M` | Kick, ban, unban, bans, invite, voice, devoice — **no channel `+o`** |
| Voice | `+v` | Autovoice, and exemption from ActiveVoice's idle devoicer |

`+M` is a custom flag, so it never collides with eggdrop's own `+m` (master).

### Granting and removing

| Command | Who can use it |
| --- | --- |
| `!addvoice <nick\|handle>` | Mod and up |
| `!addmod <nick\|handle>` | Op and up |
| `!addop <nick\|handle>` | Master and up |
| `!addmaster <nick\|handle>` | Owner |
| `!delvoice` / `!delmod` / `!delop` / `!delmaster` | Same as the matching `add` |
| `!delaccess <nick\|handle>` | Op and up — removes whichever level they hold |
| `!access [level]` | Mod and up — lists everyone with access here |

### The hierarchy rules

- **One level at a time.** Granting a level strips every other level first, globally and on
  the channel, so `!addop` on someone who was only voiced *moves* them up. No leftover flags,
  and no way for an old level to outlive the one that replaced it.
- **Promote or demote with the same command.** `!addvoice` on an op moves them back down to
  voice; the bot says which way it went.
- **You can only reach below yourself.** You can never grant a level at or above your own,
  never change someone standing level with you or above you, and never change your own access.
- **`!delop` only removes ops.** Pointed at a master it tells you so instead of quietly
  knocking them down — use `!delaccess` when you do not care which level it is.
- **Unknown nicks are registered on the spot.** `!addvoice newbie` on someone with no record
  creates one from the host the bot can see, and warns if it is an ISP host rather than a
  hidden `*.users.undernet.org` one.

Every grant, removal and refusal is written to the channel log and the bot's log.

```
<chanop> !addvoice dave
-bot- [OK] dave is now Voice on #mainchan (flags: -|v)
<chanop> !addmod dave
-bot- [OK] dave moves up from Voice to Mod on #mainchan (flags: -|Mv)
<chanop> !addop dave
-bot- You have to be above Op yourself before you can give Op to anyone.
<bigop> !addop dave
-bot- [OK] dave moves up from Mod to Op on #mainchan (flags: -|ov)
```

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

### Mods — `+M`

Kick and ban powers with no channel `+o`.

| Command | Description |
| --- | --- |
| `!kick <nick> [reason]` | Kick |
| `!ban <nick> [reason]` | Kick and ban (`*!*@host`) |
| `!unban <mask>` | Remove a ban |
| `!bans` | List the channel's bans |
| `!invite <nick>` | Invite someone in |
| `!voice [nick]` / `!devoice [nick]` | Give or take voice |
| `!addvoice` / `!delvoice` | Grant or remove Voice |
| `!access [level]` | Who has access here |

### Ops — `+o`

Everything a mod can do, plus:


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
| `!addmod` / `!delmod` | Grant or remove Mod |
| `!delaccess <handle>` | Remove whatever level someone holds |

### Masters — `+m`

| Command | Description |
| --- | --- |
| `!mode <modes>` | Set channel modes |
| `!blacklist <nick> [reason]` | Permanent ban |
| `!whitelist <mask>` | Remove from the blacklist |
| `!addop` / `!delop` | Grant or remove Op |
| `!chattr <handle> <+\|-flags>` | Change a user's flags on this channel (raw, no hierarchy) |
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
| `!addmaster` / `!delmaster` | Grant or remove Master |
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

## How idle deop works

`!idledeop #chan <hours>` sets the limit; the sweep runs every
`idledeop_check_interval` seconds and takes `+o` back from anyone who has been silent
past it. The bot has to be opped for any of it to happen.

Four things are never deopped:

- service bots in `cc(protected_bots)` — `X` and `W` by default
- the bot itself
- anyone carrying a flag from `cc(protected_flags)` — `+n` and `+m`
- anyone named in `cc(deop_exempt)`

```tcl
set cc(deop_exempt) [list "Secoupe" "Seb"]
```

That last list matches on the **nick or the handle**, case-insensitively, and is
checked before anything else. Use it for the people who run the channel: they op
themselves deliberately and are meant to keep it, and it works whether or not the bot
has a userfile record for them. Everyone else is fair game.

Don't want it at all here? `!disable idledeop`.

---

## Requirements

- eggdrop 1.8 or newer (tested on 1.10.1)
- Tcl 8.5 or newer
- The bot needs op in the channels it manages

---

## License

GPLv3 — see [LICENSE](LICENSE).
