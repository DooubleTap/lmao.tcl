# https://github.com/DooubleTap/lmao.tcl
# Enhanced version 6.2 - COMPLETE with help system, topic system, module framework, and ActiveVoice
# For UnderNet ircu with proper flag protection

###########################################################################
# CONFIGURATION SECTION - EDIT THESE VALUES
###########################################################################

# Command character trigger
set cc(cmdchar) "!"

# Main public channel
set cc(mainchan) "#mainchan"

# Back/ops channel (private)
set cc(backchan) "#secretchan"

# Back channel modes
set cc(backmode) "+s"

# Idle deop configuration
set cc(idledeop_enabled) 1
set cc(idledeop_default_hours) 3
set cc(idledeop_check_interval) 300

# ActiveVoice configuration
set cc(activevoice_idle_hours) 3
set cc(activevoice_check_interval) 300

# Flags that make a user exempt from ActiveVoice. ActiveVoice is only for
# non-regulars: anyone registered with +n, +m or +v keeps their own voice.
set cc(activevoice_exempt_flags) [list n m v]

# Self-registration: /msg <bot> register
# register_handle_max must not exceed the handlen setting in eggdrop.conf
set cc(register_enabled) 1
set cc(register_token_life) 300
set cc(register_cooldown) 600
set cc(register_handle_max) 9
set cc(register_flags) ""

# Version info
set cc(version_number) "6.2.0"
set cc(version) "\002\[lmao.tcl $cc(version_number)\]\002"
set cc(www) "https://github.com/DooubleTap/lmao.tcl"

###########################################################################
# MODULE ENABLE/DISABLE SYSTEM
###########################################################################

# Per-channel module settings (default: all ON)
array set module_settings {}

# Default module state (1 = enabled, 0 = disabled)
set module_defaults(topic) 1
set module_defaults(activevoice) 1
set module_defaults(idledeop) 1
set module_defaults(idledevoice) 1
set module_defaults(chanlog) 1

proc init_channel_modules {chan} {
	global module_defaults module_settings
	
	# Initialize all modules for this channel if not already done
	foreach {module enabled} [array get module_defaults] {
		if {![info exists module_settings($chan:$module)]} {
			set module_settings($chan:$module) $enabled
		}
	}
}

proc module_enabled {chan module} {
	global module_settings
	
	if {![info exists module_settings($chan:$module)]} {
		init_channel_modules $chan
	}
	
	return $module_settings($chan:$module)
}

proc toggle_module {chan module state} {
	global module_settings
	
	if {$state eq "on"} {
		set module_settings($chan:$module) 1
	} else {
		set module_settings($chan:$module) 0
	}
}

###########################################################################
# PROTECTED BOTS & FLAGS - DO NOT EDIT
###########################################################################

# Service bots that should NEVER be deopped
set cc(protected_bots) [list "X" "W"]

# Flags that protect users from deop/devoice
set cc(protected_flags) [list "n" "m"]

# Store idle deop settings per channel
array set idledeop_config {}

# Store topic per channel
array set topic_storage {}

# Store active voice tracking - tracks last activity time per user per channel
array set activevoice_data {}

###########################################################################
# BIND DECLARATIONS
###########################################################################

# Flag v - Voice/Devoice
bind pub n|ov [string trim $cc(cmdchar)]voice pub_do_voice
bind pub n|ov [string trim $cc(cmdchar)]devoice pub_do_devoice

# Flag o - Operator commands
bind pub n|o [string trim $cc(cmdchar)]invite pub_do_invite
bind pub n|o [string trim $cc(cmdchar)]op pub_do_op
bind msg - op pub_do_op:msg
bind msg - [string trim $cc(cmdchar)]op pub_do_op:msg
bind pub n|o [string trim $cc(cmdchar)]deop pub_do_deop
bind pub n|o [string trim $cc(cmdchar)]topic topic:pub
bind pub n|o [string trim $cc(cmdchar)]topicsync topic:sync
bind pub n|o [string trim $cc(cmdchar)]kick pub_do_kick
bind pub n|o [string trim $cc(cmdchar)]unban pub_do_unban
bind pub n|o [string trim $cc(cmdchar)]bans pub_do_bans
bind pub n|o [string trim $cc(cmdchar)]ban ban:pub

# Flag m - Master commands
bind pub n|m [string trim $cc(cmdchar)]mode pub_do_mode
bind pub n|m [string trim $cc(cmdchar)]whitelist pub_do_unperm
bind pub n|m [string trim $cc(cmdchar)]blacklist pub_do_perm
bind pub n|m [string trim $cc(cmdchar)]chattr chattr:pub
bind pub n|m [string trim $cc(cmdchar)]act pub:act
bind pub n|m [string trim $cc(cmdchar)]say pub:say
bind pub n|m [string trim $cc(cmdchar)]idledeop idledeop:pub
bind pub n|m [string trim $cc(cmdchar)]module module:pub
bind pub n|m [string trim $cc(cmdchar)]modules module:pub
bind pub n|m [string trim $cc(cmdchar)]enable module:enable:pub
bind pub n|m [string trim $cc(cmdchar)]disable module:disable:pub
bind pub n|m [string trim $cc(cmdchar)]chanlog chanlog:pub

# Module control by /msg - access is checked inside the procs so channel-only
# masters work too: /msg <bot> disable #chan idledevoice
bind msg - module module:msg
bind msg - modules module:msg
bind msg - enable module:enable:msg
bind msg - disable module:disable:msg
bind msg - chanlog chanlog:msg

# Flag n - Owner/Bot control
bind pub n [string trim $cc(cmdchar)]away pub_do_away
bind pub n [string trim $cc(cmdchar)]back pub_do_back
bind pub n [string trim $cc(cmdchar)]rehash pub_do_rehash
bind pub n [string trim $cc(cmdchar)]restart pub_do_restart
bind pub n [string trim $cc(cmdchar)]jump pub_do_jump
bind pub n [string trim $cc(cmdchar)]save pub_do_save

# Owner commands by /msg too - the n flag is re-checked inside the procs
bind msg - rehash pub_do_rehash:msg
bind msg - restart pub_do_restart:msg
bind msg - jump pub_do_jump:msg
bind msg - save pub_do_save:msg
bind pub n [string trim $cc(cmdchar)]global pub:global
bind pub n [string trim $cc(cmdchar)]part part:pub
bind pub n [string trim $cc(cmdchar)]comeback comeback:pub
bind pub n [string trim $cc(cmdchar)]join join:pub
bind pub n [string trim $cc(cmdchar)]botnick botnick:pub
bind pub n|m [string trim $cc(cmdchar)]adduser adduser:pub
bind pub n|m [string trim $cc(cmdchar)]deluser deluser:pub
bind pub n|- [string trim $cc(cmdchar)]chanset chanset:pub
bind pub n|- [string trim $cc(cmdchar)]uptime uptime:pub

# Flag - (registered users)
bind pub - [string trim $cc(cmdchar)]bot pub_do_bot
bind pub - [string trim $cc(cmdchar)]info pub_info
bind pub - [string trim $cc(cmdchar)]whois pub_whois
bind pub - [string trim $cc(cmdchar)]ops pub:alert

# Flag * (Everyone) & Help/Verify
bind pub * [string trim $cc(cmdchar)]version pub_version
bind pub * [string trim $cc(cmdchar)]help help:pub
bind pub * [string trim $cc(cmdchar)]showcommands showcommands:pub
bind pub * [string trim $cc(cmdchar)]verify verify:pub
bind msg * help help:msg
bind msg * showcommands showcommands:msg
bind msg * verify verify:msg
bind msg - register register:msg

# DCC Commands (fn flag)
bind dcc fn|fn lmao pub_lmao
bind dcc fn|fn keepalive dobinddcckeepalive
bind dcc fn|fn undokeepalive undobinddcckeepalive

# Hop on deop setting
set hopondeop 1
set kickondeop 1
bind mode - * hop:mode

# CTCP Replies
set replyctcp "[string trim $cc(version)] Get it from: $cc(www)"
bind ctcp - "VERSION" ctcp:reply
bind ctcp - "PING" ctcp:reply
bind ctcp - "TIME" ctcp:reply
bind ctcp - "FINGER" ctcp:reply

# ActiveVoice tracking - bind to PUBM to track activity
bind pubm - * activevoice:track

###########################################################################
# UTILITY FUNCTIONS
###########################################################################

# Check if user has protected flags
proc has_protected_flags {nick chan} {
	global cc
	set user_flags [chattr $nick $chan]
	
	foreach flag $cc(protected_flags) {
		if {[string match "*$flag*" $user_flags]} {
			return 1
		}
	}
	return 0
}

# Check if nick is a protected bot
proc is_protected_bot {nick} {
	global cc
	foreach bot $cc(protected_bots) {
		if {[string tolower $nick] eq [string tolower $bot]} {
			return 1
		}
	}
	return 0
}

# Get user's access level string
proc get_access_level {nick chan} {
	set flags [chattr $nick $chan]
	
	if {[string match "*n*" $flags]} {
		return "Owner (n)"
	} elseif {[string match "*m*" $flags]} {
		return "Master (m)"
	} elseif {[string match "*o*" $flags]} {
		return "Op (o)"
	} elseif {[string match "*v*" $flags]} {
		return "Voice (v)"
	} else {
		return "User (-)"
	}
}

###########################################################################
# MODULE MANAGEMENT COMMAND
###########################################################################

# What each module actually does, shown by !module list
array set module_desc {
	topic		{!topic / !topicsync - stores and re-applies the channel topic}
	activevoice	{auto-voices non-registered users when they talk}
	idledevoice	{removes voice from non-registered users idle too long}
	chanlog		{logs access, sanctions and registrations to the ops channel}
	idledeop	{deops ops who have been idle past the channel limit}
}

proc module:show {nick chan} {
	global module_defaults module_desc cc

	set c [string trim $cc(cmdchar)]

	puthelp "NOTICE $nick :\002Modules for $chan:\002"
	foreach mod [lsort [array names module_defaults]] {
		if {[module_enabled $chan $mod]} {
			set state "\00303ON\003 "
		} else {
			set state "\00304OFF\003"
		}
		if {[info exists module_desc($mod)]} {
			set what " - $module_desc($mod)"
		} else {
			set what ""
		}
		puthelp "NOTICE $nick :  \[$state\] $mod$what"
	}
	puthelp "NOTICE $nick :Use ${c}enable <module> or ${c}disable <module> (this channel only)"
}

proc module:pub {nick uhost hand chan arg} {
	global module_defaults module_settings cc

	set c [string trim $cc(cmdchar)]
	set action [string tolower [lindex [split $arg] 0]]
	set module [string tolower [lindex [split $arg] 1]]

	if {$action eq "" || $action eq "list"} {
		module:show $nick $chan
		return
	}

	if {$action ne "enable" && $action ne "disable" && $action ne "on" && $action ne "off"} {
		puthelp "NOTICE $nick :Unknown action: $action - use ${c}module list | enable <module> | disable <module>"
		return
	}

	if {$module eq ""} {
		puthelp "NOTICE $nick :Usage: ${c}module list | enable <module> | disable <module>"
		puthelp "NOTICE $nick :Available modules: [help:modules]"
		return
	}

	# Check if module exists
	if {![info exists module_defaults($module)]} {
		puthelp "NOTICE $nick :Unknown module: $module - available: [help:modules]"
		return
	}

	if {$action eq "enable" || $action eq "on"} {
		toggle_module $chan $module "on"
		puthelp "NOTICE $nick :\00303\[OK\003\] Module $module is now ENABLED in $chan"
		putlog "$nick enabled module $module in $chan"
		chanlog $chan "MODULE" "$nick enabled module \002$module\002"
	} else {
		toggle_module $chan $module "off"
		puthelp "NOTICE $nick :\00304\[OK\003\] Module $module is now DISABLED in $chan"
		putlog "$nick disabled module $module in $chan"
		chanlog $chan "MODULE" "$nick disabled module \002$module\002"
	}
}

# !enable <module> / !disable <module> - shortcuts for !module enable|disable
proc module:enable:pub {nick uhost hand chan arg} {
	module:pub $nick $uhost $hand $chan "enable [lindex [split $arg] 0]"
}

proc module:disable:pub {nick uhost hand chan arg} {
	module:pub $nick $uhost $hand $chan "disable [lindex [split $arg] 0]"
}

# /msg versions - the channel has to be named first:
#   /msg <bot> module #chan list        /msg <bot> disable #chan idledevoice
proc module:msg {nick uhost hand text} {
	global cc

	set c [string trim $cc(cmdchar)]
	set parts [split [string trim $text]]
	set chan [lindex $parts 0]
	set rest [join [lrange $parts 1 end] " "]

	if {![string match "#*" $chan]} {
		puthelp "NOTICE $nick :Usage: /msg $::botnick module <#channel> <list|enable|disable> \[module\]"
		return
	}

	if {![validchan $chan]} {
		puthelp "NOTICE $nick :I am not on $chan"
		return
	}

	if {![matchattr $hand n] && ![matchattr $hand m|m $chan]} {
		puthelp "NOTICE $nick :You do not have access to change modules on $chan"
		chanlog $chan "DENIED" "$nick tried to change modules by /msg"
		return
	}

	module:pub $nick $uhost $hand $chan $rest
}

proc module:enable:msg {nick uhost hand text} {
	set parts [split [string trim $text]]
	module:msg $nick $uhost $hand "[lindex $parts 0] enable [lindex $parts 1]"
}

proc module:disable:msg {nick uhost hand text} {
	set parts [split [string trim $text]]
	module:msg $nick $uhost $hand "[lindex $parts 0] disable [lindex $parts 1]"
}

###########################################################################
# HELP SYSTEM - every reply is delivered by NOTICE (channel and /msg alike)
# Format: Command: / Description / Example
#
# One table, one sender: !help and /msg <bot> help share the same data, so a
# command only ever has to be documented once.
#   %C% = command character     %B% = bot nick     %M% = module list
###########################################################################

# command -> {usage  description  example  /msg-example (empty = no msg bind)}
array set helpdb {
	help		{{%C%help [command]} {Shows command help. Replies always come to you by notice, never to the channel} {%C%help ban} {/msg %B% help ban}}
	showcommands	{{%C%showcommands} {Lists every command name the bot knows} {%C%showcommands} {/msg %B% showcommands}}
	op		{{%C%op [nick]} {Gives op (+o) to yourself or someone specified} {%C%op nickname} {/msg %B% op #chan nickname}}
	deop		{{%C%deop [nick]} {Removes op (+o) from a user (cannot deop +n/+m flagged users or service bots)} {%C%deop nickname} {}}
	voice		{{%C%voice [nick]} {Gives voice (+v) to yourself or someone specified} {%C%voice nickname} {}}
	devoice		{{%C%devoice [nick]} {Removes voice (+v) from a user (cannot devoice +n/+m flagged users)} {%C%devoice nickname} {}}
	invite		{{%C%invite <nick>} {Invites a user to the channel (bot must be opped)} {%C%invite someuser} {}}
	kick		{{%C%kick <nick> [reason]} {Kicks a user from the channel with optional reason} {%C%kick spammer spam detected} {}}
	ban		{{%C%ban <nick> [reason]} {Bans and kicks a user (mask: *!*@host). Protects +n/+m flags and service bots} {%C%ban baduser being annoying} {}}
	unban		{{%C%unban <*!*@host>} {Removes a ban from the channel banlist} {%C%unban *!*@example.com} {}}
	bans		{{%C%bans} {Lists all current bans on the channel with details} {%C%bans} {}}
	topic		{{%C%topic <new topic text>} {Sets and stores the channel topic (bot must be opped). Needs the topic module} {%C%topic Welcome to the channel - read the rules} {}}
	topicsync	{{%C%topicsync} {Re-applies the stored channel topic when it gets out of sync} {%C%topicsync} {}}
	mode		{{%C%mode <channel modes>} {Sets channel modes (bot must be opped). Use + or - with mode letters} {%C%mode +nt} {}}
	blacklist	{{%C%blacklist <nick> [reason]} {Permanently bans a user (mask: *!*@host) with optional reason} {%C%blacklist troll repeat offender} {}}
	whitelist	{{%C%whitelist <*!*@host>} {Removes a user from the permanent blacklist} {%C%whitelist *!*@example.com} {}}
	chattr		{{%C%chattr <handle> <+|-flags>} {Modifies a user's access flags on this channel (add with +, remove with -)} {%C%chattr john +o} {}}
	adduser		{{%C%adduser <handle> [*!*@host]} {Adds a user to the bot. Without a hostmask the nick's current host is used} {%C%adduser john *!*@his.host.com} {}}
	deluser		{{%C%deluser <handle>} {Removes a user from the bot completely} {%C%deluser john} {}}
	verify		{{%C%verify [nick]} {Shows your access level or someone elses (handle, flags, registered hosts). Given a registration code instead, it finishes your registration} {%C%verify someuser} {/msg %B% verify someuser}}
	register	{{/msg %B% register [handle]} {Registers you with the bot using the host you are on. You get a one-time code to type back, and the bot re-checks everything before saving. Auth with X and set +x first so your host is hidden} {/msg %B% register} {}}
	whois		{{%C%whois <nick>} {Shows a users access level and flags} {%C%whois someuser} {}}
	info		{{%C%info [text|none]} {Sets your personal infoline, shows it when used alone, clears it with none} {%C%info Hello, I am a channel regular} {}}
	say		{{%C%say <message text>} {Makes the bot speak a message to the channel (master+ only)} {%C%say Hello everyone} {}}
	act		{{%C%act <action text>} {Makes the bot perform an action (/me) in the channel (master+ only)} {%C%act waves at everyone} {}}
	global		{{%C%global <message text>} {Sends a message to every channel the bot is on (owner only)} {%C%global Server maintenance in 10 minutes} {}}
	ops		{{%C%ops <reason>} {Alerts the ops in the back channel that you need help here} {%C%ops someone is flooding} {}}
	module		{{%C%module <list|enable|disable> [module]} {Shows or changes which modules run on THIS channel. Modules: %M%} {%C%module list} {/msg %B% module #chan list}}
	enable		{{%C%enable <module>} {Turns a module ON for this channel. Modules: %M%} {%C%enable idledevoice} {/msg %B% enable #chan idledevoice}}
	disable		{{%C%disable <module>} {Turns a module OFF for this channel - use this to stop the idle devoicer or the idle deopper. Modules: %M%} {%C%disable idledevoice} {/msg %B% disable #chan idledevoice}}
	chanlog		{{%C%chanlog [#channel|on|off]} {Shows or sets where this channel's audit log goes. Access changes, sanctions, registrations, denied attempts and bot control all land there} {%C%chanlog #ops} {/msg %B% chanlog #chan #ops}}
	idledeop	{{%C%idledeop <#channel> [hours]} {Sets the idle-deop timer for a channel (default 3 hours). Master+ only. Switch it off with %C%disable idledeop} {%C%idledeop #canada 2} {}}
	chanset		{{%C%chanset <+|->setting} {Toggles a per-channel setting: youtube, weather, needhelp, isup} {%C%chanset +weather} {}}
	join		{{%C%join <#channel>} {Makes the bot join a channel and adds it to the channel list (owner only)} {%C%join #newchan} {}}
	part		{{%C%part <#channel>} {Makes the bot leave a channel and removes it from the channel list (owner only)} {%C%part #oldchan} {}}
	comeback	{{%C%comeback} {Makes the bot part and rejoin this channel (owner only)} {%C%comeback} {}}
	botnick		{{%C%botnick <newnick>} {Changes the bot nickname (owner only)} {%C%botnick newbotnick} {}}
	away		{{%C%away <message>} {Sets the bot away message (owner only)} {%C%away back in 10} {}}
	back		{{%C%back} {Clears the bot away message (owner only)} {%C%back} {}}
	uptime		{{%C%uptime} {Shows how long the bot has been running} {%C%uptime} {}}
	rehash		{{%C%rehash} {Reloads the bot config and scripts (owner only)} {%C%rehash} {/msg %B% rehash}}
	restart		{{%C%restart} {Restarts the bot completely (owner only)} {%C%restart} {/msg %B% restart}}
	jump		{{%C%jump} {Makes the bot jump to another IRC server (owner only)} {%C%jump} {/msg %B% jump}}
	save		{{%C%save} {Writes the userfile and channel file to disk (owner only)} {%C%save} {/msg %B% save}}
	version		{{%C%version} {Shows the bot version number and GitHub repository link} {%C%version} {}}
	bot		{{%C%bot} {Shows basic bot information (trigger character, support channel)} {%C%bot} {}}
}

# Comma separated list of every module, substituted for %M%
proc help:modules {} {
	global module_defaults
	return [join [lsort [array names module_defaults]] ", "]
}

# The one and only help sender - always NOTICE, never to the channel
proc help:send {nick text} {
	global cc botnick helpdb

	set c [string trim $cc(cmdchar)]
	set map [list %C% $c %B% $botnick %M% [help:modules]]
	set htext [string tolower [lindex [split $text] 0]]

	# Strip a leading command character so !help !ban works too
	if {[string first $c $htext] == 0} {
		set htext [string range $htext [string length $c] end]
	}

	if {$htext eq ""} {
		puthelp "NOTICE $nick :\002Quick Help:\002 Type ${c}help <command> for details - (To prevent spam, you can use /msg $botnick help <command>)"
		puthelp "NOTICE $nick :\002Common:\002 op deop voice devoice invite kick ban unban bans topic mode verify whois info ops"
		puthelp "NOTICE $nick :\002Modules:\002 ${c}module list - ${c}enable <module> - ${c}disable <module> (available: [help:modules])"
		puthelp "NOTICE $nick :Or try ${c}showcommands for the full list"
		return
	}

	if {![info exists helpdb($htext)]} {
		puthelp "NOTICE $nick :\002Unknown command:\002 $htext - Type ${c}help for the command list"
		return
	}

	foreach {usage desc example msgexample} $helpdb($htext) break

	puthelp "NOTICE $nick :\002Command:\002 [string map $map $usage]"
	puthelp "NOTICE $nick :[string map $map $desc]"
	puthelp "NOTICE $nick :\002Example:\002 [string map $map $example]"

	if {$msgexample ne ""} {
		puthelp "NOTICE $nick :\002By /msg:\002 [string map $map $msgexample]"
	}
}

proc help:pub {nick host hand chan text} {
	help:send $nick $text
}

proc help:msg {nick host hand text} {
	help:send $nick $text
}

###########################################################################
# SHOWCOMMANDS - every command name, built from the help table so the two
# can never drift apart. NOTICE only, same as help.
###########################################################################

proc showcommands:send {nick} {
	global cc botnick helpdb

	set c [string trim $cc(cmdchar)]

	puthelp "NOTICE $nick :\002All Commands:\002"

	set line ""
	foreach command [lsort [array names helpdb]] {
		append line "$command "
		if {[string length $line] > 300} {
			puthelp "NOTICE $nick :[string trimright $line]"
			set line ""
		}
	}
	if {$line ne ""} {
		puthelp "NOTICE $nick :[string trimright $line]"
	}

	puthelp "NOTICE $nick :\002Modules (per channel):\002 [help:modules] - see ${c}help module"
	puthelp "NOTICE $nick :Type ${c}help <command> for details - (To prevent spam, you can use /msg $botnick help <command>)"
}

proc showcommands:pub {nick host hand chan text} {
	showcommands:send $nick
}

proc showcommands:msg {nick host hand text} {
	showcommands:send $nick
}

###########################################################################
# CHANLOG MODULE - audit trail to the ops channel
#
# Every access change, every sanction, every registration and every piece
# of bot control lands in one channel, so the staff can read what happened
# without trawling the partyline.
#
#   !chanlog                 show where this channel logs, and whether it does
#   !chanlog #ops            send this channel's log to #ops and switch it on
#   !chanlog off             stop logging this channel
#   !chanlog on              start again, to wherever it was pointed
#
# Categories: ACCESS (who got what), SANCTION (kick/ban/deop/devoice),
# REGISTER (self-registration), MODULE (feature toggles), BOT (owner
# commands), DENIED (refused attempts at privileged commands).
###########################################################################

# chan (lowercase) -> destination channel
array set chanlog_dest {}

# Where does this channel's log go? Falls back to the configured back channel.
proc chanlog:dest {chan} {
	global cc chanlog_dest

	set key [string tolower $chan]
	if {[info exists chanlog_dest($key)]} {
		return $chanlog_dest($key)
	}
	return $cc(backchan)
}

# The one call every action site uses.
# chan "" means the event is not tied to a channel (owner commands, /msg
# registrations) - those always go to the configured back channel.
proc chanlog {chan category text} {
	global cc botnick

	if {$chan ne "" && [validchan $chan]} {
		if {![module_enabled $chan "chanlog"]} {
			return
		}
		set dest [chanlog:dest $chan]
		set where "\002$chan\002 "
	} else {
		set dest $cc(backchan)
		set where ""
	}

	if {$dest eq ""} {
		return
	}

	# Never log a channel into itself - that is how you get a feedback loop
	if {$chan ne "" && [string equal -nocase $dest $chan]} {
		return
	}

	# No point shouting at a channel the bot is not sitting in
	if {![validchan $dest] || ![botonchan $dest]} {
		return
	}

	switch -exact -- $category {
		"SANCTION" { set colour "\00304" }
		"DENIED"   { set colour "\00304" }
		"ACCESS"   { set colour "\00312" }
		"REGISTER" { set colour "\00307" }
		"MODULE"   { set colour "\00303" }
		"BOT"      { set colour "\00308" }
		default    { set colour "\00314" }
	}

	puthelp "NOTICE $dest :${colour}\[$category\]\003 $where$text"
}

proc chanlog:pub {nick uhost hand chan arg} {
	global cc chanlog_dest

	set c [string trim $cc(cmdchar)]
	set want [string trim [lindex [split $arg] 0]]
	set key [string tolower $chan]

	# --- no argument: report ---
	if {$want eq ""} {
		if {[module_enabled $chan "chanlog"]} {
			set state "\00303ON\003"
		} else {
			set state "\00304OFF\003"
		}
		set dest [chanlog:dest $chan]
		if {$dest eq ""} {
			set dest "\002nowhere\002 - set one with ${c}chanlog <#channel>"
		} elseif {![botonchan $dest]} {
			append dest " \00304(I am not on that channel)\003"
		}
		puthelp "NOTICE $nick :Channel log for \002$chan\002 is \[$state\] and goes to $dest"
		puthelp "NOTICE $nick :Change it with ${c}chanlog <#channel>, or ${c}chanlog off"
		return
	}

	# --- off / on ---
	if {[string equal -nocase $want "off"]} {
		toggle_module $chan "chanlog" "off"
		puthelp "NOTICE $nick :\00304\[OK\003\] Channel logging is now OFF for $chan"
		putlog "$nick turned channel logging off for $chan"
		chanlog "" "MODULE" "$nick turned channel logging \002off\002 for $chan"
		return
	}

	if {[string equal -nocase $want "on"]} {
		set dest [chanlog:dest $chan]
		if {$dest eq ""} {
			puthelp "NOTICE $nick :Nowhere to log to yet. Use ${c}chanlog <#channel> first."
			return
		}
		toggle_module $chan "chanlog" "on"
		puthelp "NOTICE $nick :\00303\[OK\003\] Channel logging is now ON for $chan, going to $dest"
		putlog "$nick turned channel logging on for $chan (to $dest)"
		chanlog $chan "MODULE" "$nick turned channel logging \002on\002"
		return
	}

	# --- set a destination ---
	if {![string match "#*" $want]} {
		puthelp "NOTICE $nick :Usage: ${c}chanlog <#channel> | on | off"
		return
	}

	if {[string equal -nocase $want $chan]} {
		puthelp "NOTICE $nick :I will not log \002$chan\002 into itself - pick a different channel."
		return
	}

	if {![validchan $want]} {
		puthelp "NOTICE $nick :I am not on \002$want\002. Add it first with ${c}join $want"
		return
	}

	if {![botonchan $want]} {
		puthelp "NOTICE $nick :\002$want\002 is on my channel list but I am not in it right now - logging will start once I am."
	}

	set chanlog_dest($key) $want
	toggle_module $chan "chanlog" "on"

	puthelp "NOTICE $nick :\00303\[OK\003\] $chan will now log to \002$want\002"
	putlog "$nick set the channel log for $chan to $want"
	chanlog $chan "MODULE" "$nick set the channel log to \002$want\002"
}

# /msg <bot> chanlog #channel [#dest|on|off]
proc chanlog:msg {nick uhost hand text} {
	global cc botnick

	set parts [split [string trim $text]]
	set chan [lindex $parts 0]
	set rest [join [lrange $parts 1 end] " "]

	if {![string match "#*" $chan]} {
		puthelp "NOTICE $nick :Usage: /msg $botnick chanlog <#channel> \[#logchannel|on|off\]"
		return
	}

	if {![validchan $chan]} {
		puthelp "NOTICE $nick :I am not on $chan"
		return
	}

	if {![matchattr $hand n] && ![matchattr $hand m|m $chan]} {
		puthelp "NOTICE $nick :You do not have access to change logging on $chan"
		chanlog $chan "DENIED" "$nick tried to change logging by /msg"
		return
	}

	chanlog:pub $nick $uhost $hand $chan $rest
}

###########################################################################
# SELF-REGISTRATION - /msg <bot> register
#
# Two steps on purpose:
#   1. register        -> the bot shows exactly what it would store and
#                         hands out a one-time token
#   2. verify <token>  -> the bot re-checks EVERYTHING and then registers
#
# The token has to be read out of a notice and typed back, which is what
# stops a script from registering nicks in bulk. Every check from step 1 is
# run again in step 2, because nick, host and userfile can all change in
# between.
#
# Hosts are the whole security story here. A user authed to X with usermode
# +x appears as <account>.users.undernet.org, which nobody else on the
# network can wear - that is the host worth storing. A bare ISP host is
# recycled by the ISP sooner or later, and whoever gets it next inherits the
# access, so the bot says so loudly before and after registering.
###########################################################################

# nick (lowercase) -> {token host handle issued}
array set register_pending {}

# host (lowercase) -> unixtime of last attempt
array set register_attempts {}

# 12 random characters - long enough that nobody guesses it inside the
# token's lifetime, short enough to retype from a notice
proc register:token {} {
	set chars "abcdefghijklmnopqrstuvwxyz0123456789"
	set token ""
	for {set i 0} {$i < 12} {incr i} {
		append token [string index $chars [rand [string length $chars]]]
	}
	return $token
}

# Drop tokens that have expired
proc register:cleanup {} {
	global register_pending cc

	set now [unixtime]
	foreach key [array names register_pending] {
		set issued [lindex $register_pending($key) 3]
		if {($now - $issued) > $cc(register_token_life)} {
			unset register_pending($key)
		}
	}
}

# Is this an Undernet hidden host? Those are the safe ones.
proc register:hidden_host {host} {
	return [string match -nocase "*.users.undernet.org" $host]
}

# First channel the bot shares with this nick ("" if none)
proc register:shared_chan {nick} {
	foreach chan [channels] {
		if {[onchan $nick $chan]} {
			return $chan
		}
	}
	return ""
}

# ident@host as the bot sees it on the channel, not as the user claims it
proc register:uhost_of {nick chan} {
	return [getchanhost $nick $chan]
}

# Just the host part of the above
proc register:host_of {nick chan} {
	set uhost [register:uhost_of $nick $chan]
	if {$uhost eq ""} {
		return ""
	}
	return [lindex [split $uhost "@"] end]
}

# A handle the userfile will accept
proc register:valid_handle {handle} {
	global cc

	if {[string length $handle] < 2 || [string length $handle] > $cc(register_handle_max)} {
		return 0
	}
	if {[string match "*\[ ,:@!*?#\]*" $handle]} {
		return 0
	}
	# a handle that starts with # would collide with a channel record
	if {[string index $handle 0] eq "#"} {
		return 0
	}
	return 1
}

# The advice the user gets every single time, before and after
proc register:advice {nick host} {
	global botnick

	if {[register:hidden_host $host]} {
		puthelp "NOTICE $nick :\00303Good:\003 your host is hidden by Undernet ($host). That host belongs to your X account, so nobody else can wear it."
		return
	}

	puthelp "NOTICE $nick :\00307Read this first:\003 your host is \002not\002 hidden. It is safer to auth with X and hide it \002before\002 registering:"
	puthelp "NOTICE $nick :  1. /msg x@channels.undernet.org login \002<account> <password>\002   (only ever send that to x@channels.undernet.org)"
	puthelp "NOTICE $nick :  2. /mode $nick +x     - your host becomes <account>.users.undernet.org"
	puthelp "NOTICE $nick :  3. come back and register again"
	puthelp "NOTICE $nick :Why: an ISP host like \002$host\002 gets handed to someone else when your IP changes, and they would inherit your access here."
}

proc register:msg {nick uhost hand text} {
	global cc botnick register_pending register_attempts

	if {!$cc(register_enabled)} {
		puthelp "NOTICE $nick :Self-registration is switched off. Ask a channel op to add you."
		return
	}

	register:cleanup

	# --- must be somewhere the bot can see them ---
	set chan [register:shared_chan $nick]
	if {$chan eq ""} {
		puthelp "NOTICE $nick :Join one of my channels first - I only register people I can see."
		return
	}

	# --- what host does the bot actually see? ---
	set host [register:host_of $nick $chan]
	if {$host eq "" || [string match "*\[*?\]*" $host]} {
		puthelp "NOTICE $nick :I cannot read your host right now. Try again in a moment."
		return
	}

	set mask "*!*@$host"
	set lhost [string tolower $host]
	set now [unixtime]

	# --- does the userfile already answer to this host? ---
	# Host-based identification cuts both ways: anyone sharing a registered
	# host IS that user as far as the bot is concerned. Say exactly that
	# rather than pretending to know which of them is asking.
	set owner [finduser "$nick![register:uhost_of $nick $chan]"]
	if {$owner ne "" && $owner ne "*"} {
		puthelp "NOTICE $nick :Your host (\002$host\002) already matches the user record \002$owner\002."
		puthelp "NOTICE $nick :If that record is yours you are registered already - check with /msg $botnick verify"
		puthelp "NOTICE $nick :If it is not yours, do \002not\002 register a second time - talk to a channel op."
		putlog "REGISTER: $nick ($host) asked to register, host already matches $owner"
		register:alert_ops "$nick ($host) asked to register - host already matches \002$owner\002"
		return
	}

	# --- pick the handle ---
	set words [split [string trim $text]]
	if {[llength $words] > 1} {
		puthelp "NOTICE $nick :One handle only, no spaces: /msg $botnick register <handle>"
		return
	}

	set handle [lindex $words 0]
	if {$handle eq ""} {
		set handle $nick
	}

	if {![register:valid_handle $handle]} {
		puthelp "NOTICE $nick :\002$handle\002 will not work as a handle. Use 2-$cc(register_handle_max) characters, no spaces or punctuation: /msg $botnick register <handle>"
		return
	}

	if {[validuser $handle]} {
		puthelp "NOTICE $nick :The handle \002$handle\002 is taken. Pick another: /msg $botnick register <handle>"
		return
	}

	# --- rate limit, checked last so a mistyped handle does not burn it ---
	if {[info exists register_attempts($lhost)]} {
		set wait [expr {$cc(register_cooldown) - ($now - $register_attempts($lhost))}]
		if {$wait > 0} {
			puthelp "NOTICE $nick :Too many registration attempts from your host. Try again in $wait seconds."
			return
		}
	}

	# --- everything checks out: advise, then hand out the token ---
	set token [register:token]
	set register_pending([string tolower $nick]) [list $token $host $handle $now]
	set register_attempts($lhost) $now

	register:advice $nick $host

	puthelp "NOTICE $nick :---"
	puthelp "NOTICE $nick :I would register \002$handle\002 with the hostmask \002$mask\002 and no access flags."
	puthelp "NOTICE $nick :To register please type: \002/msg $botnick verify $token\002"
	puthelp "NOTICE $nick :That code is good for [expr {$cc(register_token_life) / 60}] minutes. If you did not ask for this, ignore it - nothing has been saved."

	putlog "REGISTER: $nick ($host) requested handle $handle - token issued"
}

# Step two. Nothing from step one is trusted: it is all checked again.
proc register:confirm {nick uhost hand token} {
	global cc botnick register_pending

	register:cleanup

	set key [string tolower $nick]
	if {![info exists register_pending($key)]} {
		puthelp "NOTICE $nick :No registration is waiting for that nick, or the code expired. Start again with /msg $botnick register"
		return
	}

	foreach {want host handle issued} $register_pending($key) break

	if {$token ne $want} {
		puthelp "NOTICE $nick :That code is not right. Check the notice I sent you, or start again with /msg $botnick register"
		putlog "REGISTER: $nick sent a bad confirmation code"
		return
	}

	# --- re-run every check from step one ---
	set chan [register:shared_chan $nick]
	if {$chan eq ""} {
		puthelp "NOTICE $nick :Join one of my channels first - I only register people I can see."
		return
	}

	set now_host [register:host_of $nick $chan]
	if {$now_host eq ""} {
		puthelp "NOTICE $nick :I cannot read your host right now. Try again in a moment."
		return
	}

	if {![string equal -nocase $now_host $host]} {
		unset register_pending($key)
		puthelp "NOTICE $nick :Your host changed since you asked (\002$host\002 became \002$now_host\002), so I stopped. Start again with /msg $botnick register"
		putlog "REGISTER: $nick host changed mid-registration ($host -> $now_host) - refused"
		return
	}

	set owner [finduser "$nick![register:uhost_of $nick $chan]"]
	if {$owner ne "" && $owner ne "*"} {
		unset register_pending($key)
		puthelp "NOTICE $nick :Your host now matches the user record \002$owner\002. Nothing was changed - talk to a channel op."
		putlog "REGISTER: $nick refused at confirm - host $now_host matches $owner"
		return
	}

	if {[validuser $handle]} {
		unset register_pending($key)
		puthelp "NOTICE $nick :The handle \002$handle\002 was taken while you were deciding. Start again with /msg $botnick register <handle>"
		return
	}

	# --- register ---
	set mask "*!*@$now_host"
	adduser $handle $mask

	if {![validuser $handle]} {
		unset register_pending($key)
		puthelp "NOTICE $nick :Something went wrong writing your record. Tell a channel op."
		putlog "REGISTER: FAILED to add $handle ($mask) for $nick"
		return
	}

	if {$cc(register_flags) ne ""} {
		chattr $handle $cc(register_flags)
	}

	unset register_pending($key)
	save

	puthelp "NOTICE $nick :\00303Registered.\003 Handle \002$handle\002, hostmask \002$mask\002, no access flags - a channel op grants those."
	puthelp "NOTICE $nick :Check it any time with /msg $botnick verify"

	if {![register:hidden_host $now_host]} {
		puthelp "NOTICE $nick :Reminder: you registered an ISP host. When your IP changes you will lose access and someone else could gain it. Auth with X, set /mode $nick +x, and ask an op to move you to your hidden host."
	}

	putlog "REGISTER: $nick registered as $handle with $mask"
	register:alert_ops "$nick registered as \002$handle\002 ($mask)"
}

# Tell the ops channel what happened, so registrations are never silent
proc register:alert_ops {text} {
	chanlog "" "REGISTER" $text
}

###########################################################################
# VERIFY COMMAND - Check access levels, and confirm a registration
###########################################################################

proc verify:pub {nick host hand chan arg} {
	set target [lindex $arg 0]

	if {$target eq ""} {
		set target $nick
	}

	set target_hand [nick2hand $target $chan]

	if {$target_hand eq "*"} {
		puthelp "NOTICE $nick :\002$target\002 is not registered with the bot."
		return
	}

	if {![validuser $target_hand]} {
		puthelp "NOTICE $nick :\002$target\002 is not a registered user."
		return
	}

	set flags [chattr $target_hand $chan]
	set access [get_access_level $target_hand $chan]
	set hostmasks [getuser $target_hand hosts]

	puthelp "NOTICE $nick :\002Access Info for $target:\002"
	puthelp "NOTICE $nick :  Handle: $target_hand"
	puthelp "NOTICE $nick :  Level: $access"
	puthelp "NOTICE $nick :  Flags: $flags"
	puthelp "NOTICE $nick :  Hosts: $hostmasks"
}

# /msg <bot> verify              -> show my access
# /msg <bot> verify <nick>       -> show someone else's
# /msg <bot> verify <token>      -> finish a registration
proc verify:msg {nick host hand text} {
	global register_pending

	set arg [lindex [split [string trim $text]] 0]

	set chan [register:shared_chan $nick]

	# While a registration is pending for this nick, an argument that is not
	# somebody standing in the channel is a confirmation code - right or
	# wrong. Without this a mistyped code gets answered with "no such user",
	# which tells the person nothing about what actually went wrong.
	# Anything shaped like a code is also treated as one even with nothing
	# pending, so an expired code is answered with "it expired" rather than
	# with "no such user".
	if {$arg ne ""} {
		register:cleanup
		set key [string tolower $nick]
		set shaped_like_code [regexp {^[a-z0-9]{12}$} $arg]
		if {[info exists register_pending($key)] || $shaped_like_code} {
			if {$chan eq "" || ![onchan $arg $chan]} {
				register:confirm $nick $host $hand $arg
				return
			}
		}
	}

	if {$chan eq ""} {
		set chan "*"
	}
	verify:pub $nick $host $hand $chan $text
}

###########################################################################
# TOPIC SYSTEM - Set, Store, and Sync Channel Topics
###########################################################################

proc topic:pub {nick uhost hand chan arg} {
	global cc topic_storage
	
	if {![module_enabled $chan "topic"]} {
		putserv "NOTICE $nick :Topic module is disabled"
		return
	}
	
	set new_topic [lrange $arg 0 end]
	
	if {$new_topic eq ""} {
		putserv "NOTICE $nick :Try: [string trim $cc(cmdchar)]topic <new topic>"
		return
	}
	
	if {![botisop $chan]} {
		putserv "NOTICE $nick :I need to be op to change the topic"
		return
	}
	
	# Store topic for later sync
	set topic_storage($chan) $new_topic
	
	# Change topic on server
	putserv "TOPIC $chan :$new_topic"
	
	putlog "$nick changed topic in $chan to: $new_topic"
	chanlog $chan "ACCESS" "$nick set the topic: $new_topic"
	putserv "NOTICE $nick :Topic updated"
}

proc topic:sync {nick uhost hand chan arg} {
	global cc topic_storage
	
	if {![module_enabled $chan "topic"]} {
		putserv "NOTICE $nick :Topic module is disabled"
		return
	}
	
	# Check if we have a stored topic for this channel
	if {![info exists topic_storage($chan)]} {
		putserv "NOTICE $nick :No stored topic for $chan"
		return
	}
	
	if {![botisop $chan]} {
		putserv "NOTICE $nick :I need to be op to sync the topic"
		return
	}
	
	set stored_topic $topic_storage($chan)
	
	# Re-apply the stored topic
	putserv "TOPIC $chan :$stored_topic"
	
	putlog "$nick synced topic in $chan"
	chanlog $chan "ACCESS" "$nick re-synced the topic"
	putserv "NOTICE $nick :Topic re-synced"
}

###########################################################################
# ACTIVEVOICE MODULE - Auto-voice active users, devoice on idle
###########################################################################

# Is this nick exempt from ActiveVoice? ActiveVoice exists to voice/devoice
# NON-regulars: anyone who is a registered user carrying +n, +m or +v (global
# or on this channel) manages their own voice and is left completely alone.
proc activevoice:exempt {nick chan} {
	global cc

	set hand [nick2hand $nick $chan]
	if {$hand eq "" || $hand eq "*"} {
		return 0
	}

	if {![validuser $hand]} {
		return 0
	}

	foreach flag $cc(activevoice_exempt_flags) {
		if {[matchattr $hand $flag|$flag $chan]} {
			return 1
		}
	}

	return 0
}

proc activevoice:track {nick host hand chan text} {
	global activevoice_data cc

	if {![module_enabled $chan "activevoice"]} {
		return
	}

	# Skip service bots
	if {[is_protected_bot $nick]} {
		return
	}

	# Skip ops (they usually already have voice or op)
	if {[isop $nick $chan]} {
		return
	}

	# Skip registered regulars (+n / +m / +v) - not our business
	if {[activevoice:exempt $nick $chan]} {
		return
	}

	# Update activity time for this user in this channel
	set activevoice_data($chan:$nick) [clock seconds]

	# If user doesn't have voice yet, give it to them
	if {![isvoice $nick $chan]} {
		putserv "MODE $chan +v $nick"
	}
}

proc activevoice:devoice_idle {min hour day weekday year} {
	global activevoice_data cc botnick

	# Check all channels
	foreach chan [channels] {
		# The devoicer needs BOTH modules: activevoice does the tracking,
		# idledevoice does the removing. Either one off = nobody is devoiced.
		if {![module_enabled $chan "idledevoice"]} {
			continue
		}

		if {![module_enabled $chan "activevoice"]} {
			continue
		}

		# Make sure bot is in channel and op'd
		if {![onchan $botnick $chan]} {
			continue
		}

		if {![botisop $chan]} {
			continue
		}

		# Calculate idle threshold
		set current_time [clock seconds]
		set idle_threshold [expr {$current_time - ($cc(activevoice_idle_hours) * 3600)}]

		# Check each voiced user
		foreach user [chanlist $chan] {
			# Skip if not voiced
			if {![isvoice $user $chan]} {
				continue
			}

			# Skip service bots
			if {[is_protected_bot $user]} {
				continue
			}

			# Skip ops
			if {[isop $user $chan]} {
				continue
			}

			# Skip registered regulars (+n / +m / +v) - their voice is theirs
			if {[activevoice:exempt $user $chan]} {
				continue
			}

			# No activity recorded yet (voiced before the script loaded, or
			# voiced by X). Start their clock NOW instead of devoicing them -
			# the old code devoiced every one of them on the first tick.
			if {![info exists activevoice_data($chan:$user)]} {
				set activevoice_data($chan:$user) $current_time
				continue
			}

			# Check if idle
			set last_activity $activevoice_data($chan:$user)
			if {$last_activity < $idle_threshold} {
				# User is idle, devoice them
				putserv "MODE $chan -v $user"
				unset activevoice_data($chan:$user)
			}
		}
	}
}

###########################################################################
# ENHANCED BAN COMMAND - Ban + Kick with reason
###########################################################################

proc ban:pub {nick uhost hand chan arg} {
	global botnick cc
	
	set target [lindex $arg 0]
	set reason [lrange $arg 1 end]
	
	if {$target eq ""} {
		putserv "NOTICE $nick :Try: [string trim $cc(cmdchar)]ban <nick> \[reason\]"
		return
	}
	
	# Check if target is online
	if {![onchan $target $chan]} {
		putserv "NOTICE $nick :$target is not on $chan"
		return
	}
	
	# Protect the bot
	if {[string tolower $target] eq [string tolower $botnick]} {
		putserv "KICK $chan $nick :Nice try buddy"
		return
	}
	
	# Protect owner/master flags
	set target_hand [nick2hand $target $chan]
	if {$target_hand ne "*" && [has_protected_flags $target_hand $chan]} {
		putserv "KICK $chan $nick :Can't ban someone with protected flags"
		return
	}
	
	# Create ban mask
	set hostmask [getchanhost $target $chan]
	if {$hostmask eq ""} {
		set ban_mask "*!*@*"
	} else {
		set ban_mask "*!*@[lindex [split $hostmask @] 1]"
	}
	
	# Apply ban
	putserv "MODE $chan +b $ban_mask"
	
	# Set default reason if none provided
	if {$reason eq ""} {
		set reason "banned by $nick"
	}
	
	# Kick with reason
	putserv "KICK $chan $target :$reason"
	
	# Log to backchannel
	putserv "PRIVMSG $cc(backchan) :\00304\[BAN\003\] $nick banned $target ($ban_mask) - Reason: $reason"
	
	putlog "$nick banned $target ($ban_mask) from $chan - Reason: $reason"
	chanlog $chan "SANCTION" "$nick banned \002$target\002 ($ban_mask) - $reason"
}

###########################################################################
# DEOP WITH FLAG PROTECTION
###########################################################################

proc pub_do_deop {nick host handle channel args} {
	global botnick cc
	
	set who [lindex $args 0]
	
	if {$who eq ""} {
		putserv "MODE $channel -o $nick"
		return
	}
	
	# Protect service bots
	if {[is_protected_bot $who]} {
		putserv "NOTICE $nick :Cannot deop protected service bot $who"
		return
	}
	
	# Protect the bot itself
	if {[string tolower $who] eq [string tolower $botnick]} {
		putserv "NOTICE $nick :I won't deop myself"
		return
	}
	
	# Protect users with protected flags
	set target_hand [nick2hand $who $channel]
	if {$target_hand ne "*" && [has_protected_flags $target_hand $channel]} {
		putserv "NOTICE $nick :Cannot deop user with protected flags"
		putserv "KICK $channel $nick :Nice try"
		return
	}
	
	# Self-deop is allowed
	if {[string tolower $who] eq [string tolower $nick]} {
		putserv "MODE $channel -o $nick"
		return
	}
	
	# Check if target is actually op'd
	if {![isop $who $channel]} {
		putserv "NOTICE $nick :$who is not op'd on $channel"
		return
	}
	
	# Perform deop
	putserv "MODE $channel -o $who"
	putlog "$nick deopped $who from $channel"
	chanlog $channel "SANCTION" "$nick deopped \002$who\002"
}

###########################################################################
# DEVOICE WITH FLAG PROTECTION
###########################################################################

proc pub_do_devoice {nick host handle channel args} {
	global botnick cc
	
	set who [lindex $args 0]
	
	if {$who eq ""} {
		putserv "MODE $channel -v $nick"
		return
	}
	
	# Protect service bots
	if {[is_protected_bot $who]} {
		putserv "NOTICE $nick :Cannot devoice protected service bot $who"
		return
	}
	
	# Protect the bot
	if {[string tolower $who] eq [string tolower $botnick]} {
		putserv "MODE $channel -v $nick"
		return
	}
	
	# Protect users with protected flags
	set target_hand [nick2hand $who $channel]
	if {$target_hand ne "*" && [has_protected_flags $target_hand $channel]} {
		putserv "KICK $channel $nick :Nice try"
		return
	}
	
	# Self-devoice allowed
	if {[string tolower $who] eq [string tolower $nick]} {
		putserv "MODE $channel -v $nick"
		return
	}
	
	# Check if actually voiced
	if {![isvoice $who $channel]} {
		putserv "NOTICE $nick :$who is not voiced on $channel"
		return
	}
	
	# Perform devoice
	putserv "MODE $channel -v $who"
	putlog "$nick devoiced $who in $channel"
	chanlog $channel "SANCTION" "$nick devoiced \002$who\002"
}

###########################################################################
# IDLE DEOP MODULE
###########################################################################

proc idledeop:pub {nick uhost hand chan arg} {
	global cc idledeop_config
	
	if {![module_enabled $chan "idledeop"]} {
		putserv "NOTICE $nick :Idle deop module is disabled"
		return
	}
	
	set target_chan [lindex $arg 0]
	set hours [lindex $arg 1]
	
	if {$target_chan eq ""} {
		putserv "NOTICE $nick :Try: [string trim $cc(cmdchar)]idledeop <#channel> \[hours\]"
		return
	}
	
	# Validate channel format
	if {![string match "#*" $target_chan]} {
		putserv "NOTICE $nick :Invalid channel format, must start with #"
		return
	}
	
	# Set default if not specified
	if {$hours eq ""} {
		set hours $cc(idledeop_default_hours)
	}
	
	# Validate hour input
	if {![string is integer -strict $hours]} {
		putserv "NOTICE $nick :Hours must be a number"
		return
	}
	
	if {$hours < 1 || $hours > 48} {
		putserv "NOTICE $nick :Hours must be between 1 and 48"
		return
	}
	
	# Store configuration
	set idledeop_config($target_chan) $hours
	
	putserv "NOTICE $nick :Idle deop set for $target_chan: $hours hours"
	putserv "PRIVMSG $cc(backchan) :\00303\[IDLEDEOP\003\] $nick configured idle deop for $target_chan: $hours hours"
	putlog "$nick set idle deop for $target_chan to $hours hours"
	chanlog $chan "MODULE" "$nick set idle deop for $target_chan to $hours hours"
}

proc idledeop:timer {min hour day weekday year} {
	global botnick cc idledeop_config
	
	# Check all channels with idledeop configured
	foreach chan [array names idledeop_config] {
		set hours $idledeop_config($chan)
		
		if {![module_enabled $chan "idledeop"]} {
			continue
		}
		
		# Check if bot is in channel and op'd
		if {![onchan $botnick $chan]} {
			continue
		}
		
		if {![botisop $chan]} {
			continue
		}
		
		# Get current time
		set current_time [clock seconds]
		set idle_threshold [expr {$current_time - ($hours * 3600)}]
		
		# Get list of all users in channel
		foreach user [chanlist $chan] {
			# Skip service bots
			if {[is_protected_bot $user]} {
				continue
			}
			
			# Skip the bot itself
			if {[string tolower $user] eq [string tolower $botnick]} {
				continue
			}
			
			# Only process ops
			if {![isop $user $chan]} {
				continue
			}
			
			# Check if user has protected flags
			set user_hand [nick2hand $user $chan]
			if {$user_hand ne "*" && [has_protected_flags $user_hand $chan]} {
				continue
			}
			
			# Get user's idle time
			set user_idle [getchanidle $user $chan]
			
			if {$user_idle >= $idle_threshold} {
				# User is idle, deop them
				putserv "MODE $chan -o $user"
				putserv "PRIVMSG $chan :$user has been deopped for idleness ($hours hours)"
				putlog "Idle deop: $user deopped from $chan (idle: $user_idle seconds)"
				chanlog $chan "SANCTION" "auto: deopped \002$user\002 after [expr {$user_idle / 60}] minutes idle"
			}
		}
	}
}

###########################################################################
# EXISTING COMMANDS - FULL IMPLEMENTATIONS
###########################################################################

proc pub_do_invite {nick host handle channel text} {
	global botnick cc
	set who [lindex [split $text] 0]
	
	if {$who eq ""} {
		putserv "NOTICE $nick :Try: [string trim $cc(cmdchar)]invite <nick>"
		return
	}
	
	if {[string tolower $who] eq [string tolower $nick]} {
		putserv "NOTICE $nick :Really?"
		return
	}
	
	if {[string tolower $who] eq [string tolower $botnick]} {
		putserv "NOTICE $nick :Really?"
		return
	}
	
	if {[onchan $who $channel]} {
		putserv "NOTICE $nick :$who is already here"
		return
	}
	
	putserv "INVITE $who :$channel"
	putserv "NOTICE $nick :Done"
	putserv "NOTICE $who :You have been invited to $channel by $nick"
}

proc pub_do_op {nick host handle channel args} {
	global botnick
	
	set who [lindex $args 0]
	
	if {$who eq ""} {
		if {![botisop $channel]} {
			putserv "NOTICE $nick :I am not op on $channel!"
			return
		}
		
		if {[isop $nick $channel]} {
			putserv "NOTICE $nick :You're already op"
			return
		}
		
		putserv "MODE $channel +o $nick"
		return
	}
	
	if {![botisop $channel]} {
		putserv "NOTICE $nick :I am not op on $channel!"
		return
	}
	
	if {[isop $who $channel]} {
		putserv "NOTICE $nick :$who is already op"
		return
	}
	
	putserv "MODE $channel +o $who"
	putlog "$nick made me op $who in $channel"
	chanlog $channel "ACCESS" "$nick opped \002$who\002"
}

proc pub_do_op:msg {nick host handle text} {
	global botnick

	set parts [split [string trim $text]]
	set chan [lindex $parts 0]
	set who [lindex $parts 1]

	if {![string match "#*" $chan]} {
		puthelp "NOTICE $nick :Usage: /msg $botnick op <#channel> \[nick\]"
		return
	}

	if {![validchan $chan]} {
		puthelp "NOTICE $nick :I am not on $chan"
		return
	}

	if {![matchattr $handle n] && ![matchattr $handle o|o $chan]} {
		puthelp "NOTICE $nick :You do not have op access on $chan"
		chanlog $chan "DENIED" "$nick tried to op by /msg"
		return
	}

	pub_do_op $nick $host $handle $chan $who
}

proc pub_do_voice {nick host handle channel args} {
	global botnick
	
	set who [lindex $args 0]
	
	if {$who eq ""} {
		if {![botisop $channel]} {
			putserv "NOTICE $nick :I am not op on $channel!"
			return
		}
		
		if {[isvoice $nick $channel]} {
			putserv "MODE $channel +v $nick"
			return
		}
		
		putserv "MODE $channel +v $nick"
		return
	}
	
	if {![botisop $channel]} {
		putserv "NOTICE $nick :I am not op on $channel!"
		return
	}
	
	if {[isvoice $who $channel]} {
		putserv "NOTICE $nick :$who is already voiced"
		return
	}
	
	putserv "MODE $channel +v $who"
	putlog "$nick voiced $who in $channel"
	chanlog $channel "ACCESS" "$nick voiced \002$who\002"
}

proc pub_do_kick {nick uhost hand chan args} {
	global botnick cc
	
	set who [lindex $args 0]
	set why [lrange $args 1 end]
	
	if {![onchan $who $chan]} {
		putserv "NOTICE $nick :$who is not on $chan"
		return
	}
	
	if {[string tolower $who] eq [string tolower $botnick]} {
		putserv "KICK $chan $nick :nice try"
		return
	}
	
	if {$who eq ""} {
		putserv "NOTICE $nick :Try: [string trim $cc(cmdchar)]kick <nick> \[reason\]"
		return
	}
	
	if {[string tolower $who] eq [string tolower $nick]} {
		putserv "NOTICE $nick :no"
		return
	}
	
	set target_hand [nick2hand $who $chan]
	if {$target_hand ne "*" && [has_protected_flags $target_hand $chan]} {
		putserv "KICK $chan $nick :Nice Try"
		return
	}
	
	if {$why eq ""} {
		putserv "KICK $chan $who"
		set why "no reason given"
	} else {
		putserv "KICK $chan $who :$why"
	}

	putlog "$nick kicked $who from $chan - Reason: $why"
	chanlog $chan "SANCTION" "$nick kicked \002$who\002 - $why"
}

proc pub_do_unban {nick host handle channel args} {
	set who [lindex $args 0]
	
	if {$who eq ""} {
		putserv "NOTICE $nick :Try: [string trim $cc(cmdchar)]unban <*!*@host>"
		return
	}
	
	putserv "MODE $channel -b $who"
	putlog "$nick removed ban $who from $channel"
	chanlog $channel "SANCTION" "$nick removed ban $who"
}

proc pub_do_unperm {nick host handle channel args} {
	set who [lindex $args 0]
	
	if {$who eq ""} {
		putserv "NOTICE $nick :Try: [string trim $cc(cmdchar)]whitelist <*!*@host>"
		return
	}
	
	killchanban $channel $who
	putlog "$nick removed blacklist $who from $channel"
	chanlog $channel "SANCTION" "$nick whitelisted $who"
}

proc pub_do_bans {nick uhost hand chan text} {
	puthelp "NOTICE $nick :-Ban List for ($chan)-"
	foreach {a b c d} [banlist $chan] {
		puthelp "NOTICE $nick :- [format %-15s%-15s%-15s%-15s $a $b $c $d]"
	}
	puthelp "NOTICE $nick :-End of list-"
}

proc pub_do_perm {nick host handle channel args} {
	global botnick cc
	
	set who [lindex $args 0]
	set reason [lrange $args 1 end]
	
	if {$who eq ""} {
		putserv "NOTICE $nick :Usage: [string trim $cc(cmdchar)]blacklist <nick> \[reason\]"
		return
	}
	
	if {![onchan $who $channel]} {
		putserv "NOTICE $nick :$who is not on $channel"
		return
	}
	
	if {[string tolower $who] eq [string tolower $botnick]} {
		putserv "KICK $channel $nick :no"
		return
	}
	
	set target_hand [nick2hand $who $channel]
	if {$target_hand ne "*" && [has_protected_flags $target_hand $channel]} {
		putserv "NOTICE $who :$nick tried to blacklist you"
		putserv "NOTICE $nick :Not going to happen!"
		return
	}
	
	set ban [maskhost [getchanhost $who $channel]]
	newchanban $channel $ban $nick $reason
	stick $ban $channel
	putserv "KICK $channel $who :$reason"
	putserv "NOTICE $nick :Blacklisted: $who - $reason"
	putlog "$nick blacklisted $who ($ban) - Reason: $reason"
	chanlog $channel "SANCTION" "$nick blacklisted \002$who\002 ($ban) - $reason"
}

proc pub_do_away {nick host handle channel args} {
	global cc
	set why [lrange $args 0 end]
	
	if {$why eq ""} {
		putserv "NOTICE $nick :Try: [string trim $cc(cmdchar)]away <message>"
		return
	}
	
	putserv "AWAY :$why"
	putserv "NOTICE $nick :Away message set"
}

proc pub_do_back {nick host handle channel args} {
	putserv "AWAY :"
	putserv "NOTICE $nick :I'm back"
}

proc pub_do_mode {nick host handle channel args} {
	global cc
	set who [lindex $args 0]
	
	if {![botisop $channel]} {
		putserv "NOTICE $nick :I'm not op'd in $channel!"
		return
	}
	
	if {$who eq ""} {
		putserv "NOTICE $nick :Usage: [string trim $cc(cmdchar)]mode <modes>"
		return
	}
	
	putserv "MODE $channel $who"
	putlog "$nick set mode $who in $channel"
	chanlog $channel "ACCESS" "$nick set mode \002$who\002"
}

# Owner commands. The notice goes out BEFORE the action - restart and jump
# drop the send queue, so a notice queued afterwards is never delivered.
proc pub_do_rehash {nick host handle channel args} {
	putquick "NOTICE $nick :Rehashing TCL script(s)"
	putlog "$nick requested a rehash"
	chanlog "" "BOT" "$nick reloaded the scripts (rehash)"
	rehash
}

proc pub_do_restart {nick host handle channel args} {
	putquick "NOTICE $nick :Restarting bot"
	putlog "$nick requested a restart"
	chanlog "" "BOT" "$nick restarted the bot"
	restart
}

proc pub_do_jump {nick host handle channel args} {
	putquick "NOTICE $nick :Jumping servers"
	putlog "$nick requested a server jump"
	chanlog "" "BOT" "$nick made me jump servers"
	jump
}

proc pub_do_save {nick host handle channel args} {
	save
	putquick "NOTICE $nick :Saved user file and channel file"
	putlog "$nick requested a userfile save"
	chanlog "" "BOT" "$nick saved the userfile"
}

# /msg versions - owner only, checked here because msg binds match global flags
proc owner:msg {nick host handle text command} {
	if {![matchattr $handle n]} {
		puthelp "NOTICE $nick :That command is owner only"
		set what [string map {pub_do_ ""} $command]
		putlog "$nick ($handle) tried $what by /msg - denied"
		chanlog "" "DENIED" "$nick ($handle) tried \002$what\002 by /msg"
		return
	}
	$command $nick $host $handle "msg" ""
}

proc pub_do_rehash:msg {nick host handle text} {
	owner:msg $nick $host $handle $text pub_do_rehash
}

proc pub_do_restart:msg {nick host handle text} {
	owner:msg $nick $host $handle $text pub_do_restart
}

proc pub_do_jump:msg {nick host handle text} {
	owner:msg $nick $host $handle $text pub_do_jump
}

proc pub_do_save:msg {nick host handle text} {
	owner:msg $nick $host $handle $text pub_do_save
}

proc chanset:pub {nick uhost hand chan arg} {
	global cc
	set mode [lindex [split $arg] 0]
	
	if {[regexp {^[+-](youtube|weather|needhelp|isup)$} $mode]} {
		channel set $chan $mode
		putserv "NOTICE $nick :Set mode on $chan: \00312$mode\003"
	} else {
		putserv "NOTICE $nick :\002USAGE\002 - [string trim $cc(cmdchar)]chanset <+|->setting"
	}
}

proc comeback:pub {nick uhost hand chan text} {
	putserv "PART $chan :coming right back"
	after 1000
	putserv "JOIN $chan"
}

proc hop:mode {nick uhost hand chan mc vict} {
	global hopondeop kickondeop botnick
	
	if {$mc eq "-o" && $vict eq $botnick && $hopondeop eq 1} {
		putlog "Hopping channel $chan due to deop"
		putserv "PART $chan :Trying to fix something"
		after 1000
		putserv "JOIN $chan"
		
		if {$nick ne $botnick && $kickondeop eq 1} {
			after 2000
			putserv "KICK $chan $nick"
		}
	}
}

proc join:pub {nick uhost hand chan text} {
	global cc
	set target [lindex $text 0]
	
	if {$target eq ""} {
		putserv "NOTICE $nick :Try: [string trim $cc(cmdchar)]join <#channel>"
		return
	}
	
	putlog "Joining $target at $nick's request"
	chanlog "" "BOT" "$nick had me join \002$target\002"
	putserv "JOIN :$target"
	channel add $target
}

proc part:pub {nick uhost hand chan text} {
	global cc
	set target [lindex $text 0]
	
	if {$target eq ""} {
		putserv "NOTICE $nick :Try: [string trim $cc(cmdchar)]part <#channel>"
		return
	}
	
	if {![validchan $target]} {
		putserv "NOTICE $nick :$target is not a valid channel"
		return
	}
	
	putlog "Parting $target at $nick's request"
	chanlog "" "BOT" "$nick had me leave \002$target\002"
	putserv "PART $target :bye"
	channel remove $target
}

proc botnick:pub {mynick uhost hand chan text} {
	global cc
	set newnick $text
	
	if {$newnick eq ""} {
		putserv "NOTICE $mynick :Try: [string trim $cc(cmdchar)]botnick <newnick>"
		return
	}
	
	putlog "Changing botnick to $newnick"
	chanlog "" "BOT" "$mynick changed my nick to \002$newnick\002"
	putserv "NICK $newnick"
}

proc ctcp:reply {nick host hand dest key text} {
	global cc
	putserv "NOTICE $nick :$cc(version) - $cc(www)"
	return 0
}

proc uptime:pub {nick host handle chan arg} {
	global uptime
	set current_time [unixtime]
	set uptime_seconds [expr {$current_time - $uptime}]
	puthelp "NOTICE $nick :My uptime is [format_duration $uptime_seconds]"
}

proc format_duration {seconds} {
	set days [expr {$seconds / 86400}]
	set hours [expr {($seconds % 86400) / 3600}]
	set minutes [expr {($seconds % 3600) / 60}]
	set secs [expr {$seconds % 60}]
	
	return "${days}d ${hours}h ${minutes}m ${secs}s"
}

proc chattr:pub {nick uhost handle chan arg} {
	global cc
	set target [lindex $arg 0]
	set flags [lindex $arg 1]
	
	if {$target eq ""} {
		puthelp "NOTICE $nick :Usage: [string trim $cc(cmdchar)]chattr <handle> <+|->flags"
		return
	}
	
	if {![validuser $target]} {
		puthelp "NOTICE $nick :$target is not a valid user"
		return
	}
	
	if {$flags eq ""} {
		puthelp "NOTICE $nick :Usage: [string trim $cc(cmdchar)]chattr <handle> <+|->flags"
		return
	}
	
	chattr $target |$flags $chan
	puthelp "NOTICE $nick :Updated flags for $target"
	putlog "$nick set flags $flags on $target in $chan"
	chanlog $chan "ACCESS" "$nick set flags \002$flags\002 on \002$target\002"
}

proc adduser:pub {nick uhost handle chan arg} {
	global cc
	set newuser [lindex $arg 0]
	set hostmask [lindex $arg 1]
	
	if {$newuser eq ""} {
		puthelp "NOTICE $nick :Usage: [string trim $cc(cmdchar)]adduser <handle> \[*!*@host\]"
		return
	}
	
	if {[validuser $newuser]} {
		puthelp "NOTICE $nick :$newuser already exists!"
		return
	}
	
	if {$hostmask eq ""} {
		set hostmask "*!*@unknown.host"
	}
	
	adduser $newuser $hostmask
	puthelp "NOTICE $nick :User $newuser added"
	putlog "$nick added user $newuser ($hostmask)"
	chanlog $chan "ACCESS" "$nick added user \002$newuser\002 ($hostmask)"
}

proc deluser:pub {nick uhost handle chan arg} {
	global cc
	set user [lindex $arg 0]
	
	if {$user eq ""} {
		puthelp "NOTICE $nick :Usage: [string trim $cc(cmdchar)]deluser <handle>"
		return
	}
	
	if {![validuser $user]} {
		puthelp "NOTICE $nick :$user does not exist"
		return
	}
	
	deluser $user
	puthelp "NOTICE $nick :User $user deleted"
	putlog "$nick deleted user $user"
	chanlog $chan "ACCESS" "$nick deleted user \002$user\002"
}

proc pub_whois {nick uhost handle chan text} {
	global cc
	
	set target [lindex [split $text] 0]
	
	if {$target eq ""} {
		set target $nick
	}
	
	set target_hand [nick2hand $target $chan]
	
	if {$target_hand eq "*"} {
		puthelp "NOTICE $nick :$target is not registered with the bot"
		return
	}
	
	set flags [chattr $target_hand $chan]
	set access [get_access_level $target_hand $chan]
	
	puthelp "NOTICE $nick :WHOIS: $target ($target_hand) - Level: $access - Flags: $flags"
}

proc pub_version {nick uhost handle chan arg} {
	global cc
	puthelp "NOTICE $nick :$cc(version) available at: $cc(www)"
}

proc pub:alert {nick uhost handle chan arg} {
	global cc
	puthelp "NOTICE $cc(backchan) :\00304\[OPS\003\] $nick calling ops in $chan: $arg"
}

proc pub_info {nick uhost handle chan arg} {
	if {$arg eq "none"} {
		setchaninfo $handle $chan "none"
		puthelp "NOTICE $nick :Infoline removed"
		return
	}
	
	if {$arg ne ""} {
		setchaninfo $handle $chan $arg
		puthelp "NOTICE $nick :Infoline set"
		return
	}
	
	set info [getchaninfo $handle $chan]
	if {$info eq ""} {
		puthelp "NOTICE $nick :You don't have an infoline set"
	} else {
		puthelp "NOTICE $nick :Your infoline: $info"
	}
}

proc pub:say {nick uhost handle chan arg} {
	puthelp "PRIVMSG $chan :$arg"
	chanlog $chan "ACCESS" "$nick made me say: $arg"
}

proc pub:global {nick uhost handle chan arg} {
	foreach c [channels] {
		puthelp "PRIVMSG $c :\[GLOBAL\] $arg"
	}
	putlog "$nick sent a global: $arg"
	chanlog "" "BOT" "$nick sent a global message: $arg"
}

proc pub:act {nick uhost handle chan arg} {
	puthelp "PRIVMSG $chan :\001ACTION $arg\001"
	chanlog $chan "ACCESS" "$nick made me act: $arg"
}

proc pub_do_bot {nick host hand channel text} {
	global cc botnick
	puthelp "NOTICE $nick :Trigger: [string trim $cc(cmdchar)]"
	puthelp "NOTICE $nick :Main support channel: $cc(backchan)"
	puthelp "NOTICE $nick :Type: /msg $botnick help - for full command list"
}

proc dobinddcckeepalive {handle idx text} {
	bind cron - "* * * * *" dcckeepalive
	putdcc $idx "Keep-alive enabled"
	return 0
}

proc dcckeepalive {min hour day weekday year} {
	if {[hand2idx DooubleTap] > 0} {
		putdcc [hand2idx DooubleTap] " "
	}
}

proc undobinddcckeepalive {handle idx text} {
	unbind cron - "* * * * *" dcckeepalive
	putdcc $idx "Keep-alive disabled"
	return 0
}

proc pub_lmao {handle idx text} {
	global cc
	putidx $idx "Welcome to lmao.tcl"
	putidx $idx "Version: $cc(version_number)"
	putidx $idx "Repository: $cc(www)"
	putidx $idx " "
	putidx $idx "Type 'help' on the partyline for more information"
}

###########################################################################
# TIMER INITIALIZATION - Set up recurring checks
###########################################################################

proc setup_timers {} {
	global cc

	# Kill any leftover timers first - without this a .rehash (or the old
	# re-arm bug) stacks duplicate timers until every check runs many times
	foreach t [utimers] {
		if {[lindex $t 1] eq "idledeop:timer_check" || [lindex $t 1] eq "activevoice:timer_check"} {
			killutimer [lindex $t 2]
		}
	}

	# Schedule idle deop check
	utimer $cc(idledeop_check_interval) idledeop:timer_check

	# Schedule activevoice idle devoice check
	utimer $cc(activevoice_check_interval) activevoice:timer_check
}

# Each check re-arms ONLY itself. Calling setup_timers here (as the old code
# did) doubled the number of running timers on every single tick.
proc idledeop:timer_check {} {
	global cc
	idledeop:timer 0 0 0 0 0
	utimer $cc(idledeop_check_interval) idledeop:timer_check
}

proc activevoice:timer_check {} {
	global cc
	activevoice:devoice_idle 0 0 0 0 0
	utimer $cc(activevoice_check_interval) activevoice:timer_check
}

###########################################################################
# INITIALIZATION
###########################################################################

# Initialize module system for main channel
init_channel_modules $cc(mainchan)

# Set up recurring timers
setup_timers

putlog "$cc(version) - Complete production ready version"
putlog "Loaded successfully - ready to serve!"
