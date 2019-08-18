--[[
Re-write functions (from builtin commands).
Copyright (C) 2019 Panquesito7

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
USA
--]]

local S = enhanced_builtin_commands.intllib

function enhanced_builtin_commands.grant_command(caller, grantname, grantprivstr)
	local caller_privs = core.get_player_privs(caller)
	if not (caller_privs.privs or caller_privs.basic_privs) then
		return false, S("Your privileges are insufficient.")
	end

	if not core.get_auth_handler().get_auth(grantname) then
		return false, S("Player @1 does not exist.", grantname)
	end
	local grantprivs = core.string_to_privs(grantprivstr)
	if grantprivstr == "all" then
		grantprivs = core.registered_privileges
	end
	local privs = core.get_player_privs(grantname)
	local privs_unknown = ""
	local basic_privs =
		core.string_to_privs(core.settings:get("basic_privs") or "interact,shout")
	for priv, _ in pairs(grantprivs) do
		if not basic_privs[priv] and not caller_privs.privs then
			return false, S("Your privileges are insufficient.")
		end
		if not core.registered_privileges[priv] then
			privs_unknown = privs_unknown .. S("Unknown privilege: @1\n", priv)
		end
		privs[priv] = true
	end
	if privs_unknown ~= "" then
		return false, privs_unknown
	end
	for priv, _ in pairs(grantprivs) do
		core.run_priv_callbacks(grantname, priv, caller, "grant")
	end
	core.set_player_privs(grantname, privs)
	core.log("action", caller..' granted ('..core.privs_to_string(grantprivs, ', ')..') privileges to '..grantname)
	if grantname ~= caller then
		core.chat_send_player(grantname, S("@1 granted you privileges: @2", caller, core.privs_to_string(grantprivs, ' ')))
	end
	return true, S("Privileges of @1: @2", grantname, core.privs_to_string(core.get_player_privs(grantname), ' '))
end

function enhanced_builtin_commands.emergeblocks_callback(pos, action, num_calls_remaining, ctx)
	if ctx.total_blocks == 0 then
		ctx.total_blocks   = num_calls_remaining + 1
		ctx.current_blocks = 0
	end
	ctx.current_blocks = ctx.current_blocks + 1

	if ctx.current_blocks == ctx.total_blocks then
		core.chat_send_player(ctx.requestor_name,
			string.format(S("Finished emerging %d blocks in %.2fms.", 
			ctx.total_blocks, (os.clock() - ctx.start_time) * 1000)))
	end
end

function enhanced_builtin_commands.emergeblocks_progress_update(ctx)
	if ctx.current_blocks ~= ctx.total_blocks then
		core.chat_send_player(ctx.requestor_name,
			string.format(S("emergeblocks update: %d/%d blocks emerged (%.1f%%)",
			ctx.current_blocks, ctx.total_blocks,
			(ctx.current_blocks / ctx.total_blocks) * 100)))

		core.after(2, emergeblocks_progress_update, ctx)
	end
end

function enhanced_builtin_commands.handle_give_command(cmd, giver, receiver, stackstring)
	core.log("action", giver .. " invoked " .. cmd
			.. ', stackstring="' .. stackstring .. '"')
	local itemstack = ItemStack(stackstring)
	if itemstack:is_empty() then
		return false, S("Cannot give an empty item")
	elseif (not itemstack:is_known()) or (itemstack:get_name() == "unknown") then
		return false, S("Cannot give an unknown item")
	-- Forbid giving 'ignore' due to unwanted side effects
	elseif itemstack:get_name() == "ignore" then
		return false, S("Giving 'ignore' is not allowed")
	end
	local receiverref = core.get_player_by_name(receiver)
	if receiverref == nil then
		return false, S("@1 is not a known player", receiver)
	end
	local leftover = receiverref:get_inventory():add_item("main", itemstack)
	local partiality
	if leftover:is_empty() then
		partiality = ""
	elseif leftover:get_count() == itemstack:get_count() then
		partiality = S("could not be ")
	else
		partiality = S("partially ")
	end
	-- The actual item stack string may be different from what the "giver"
	-- entered (e.g. big numbers are always interpreted as 2^16-1).
	stackstring = itemstack:to_string()
	if giver == receiver then
		local msg = S("%q %sadded to inventory.")
		return true, msg:format(stackstring, partiality)
	else
		core.chat_send_player(receiver, S("%q %sadded to inventory.", format(stackstring, partiality)))
		local msg = S("%q %sadded to %s's inventory.")
		return true, msg:format(stackstring, partiality, receiver)
	end
end

function enhanced_builtin_commands.handle_kill_command(killer, victim)
	if core.settings:get_bool("enable_damage") == false then
		return false, S("Players can't be killed, damage has been disabled.")
	end
	local victimref = core.get_player_by_name(victim)
	if victimref == nil then
		return false, S("Player @1 is not online.", victim)
	elseif victimref:get_hp() <= 0 then
		if killer == victim then
			return false, S("You are already dead.")
		else
			return false, S("@1 is already dead.", victim)
		end
	end
	if not killer == victim then
		core.log("action", string.format("%s killed %s", killer, victim))
	end
	-- Kill victim
	victimref:set_hp(0)
	return true, S("@1 has been killed.", victim)
end

function enhanced_builtin_commands.parse_range_str(player_name, str)
	local p1, p2
	local args = str:split(" ")

	if args[1] == "here" then
		p1, p2 = core.get_player_radius_area(player_name, tonumber(args[2]))
		if p1 == nil then
			return false, S("Unable to get player @1 position", player_name)
		end
	else
		p1, p2 = core.string_to_area(str)
		if p1 == nil then
			return false, S("Incorrect area format. Expected: (x1,y1,z1) (x2,y2,z2)")
		end
	end

	return p1, p2
end

local cmd_marker = "/"

function enhanced_builtin_commands.do_help_cmd(name, param)
	function enhanced_builtin_commands.format_help_line(cmd, def)
		local msg = core.colorize("#00ffff", cmd_marker .. cmd)
		if def.params and def.params ~= "" then
			msg = msg .. " " .. def.params
		end
		if def.description and def.description ~= "" then
			msg = msg .. ": " .. def.description
		end
		return msg
	end
	if param == "" then
		local cmds = {}
		for cmd, def in pairs(core.registered_chatcommands) do
			if INIT == "client" or core.check_player_privs(name, def.privs) then
				cmds[#cmds + 1] = cmd
			end
		end
		table.sort(cmds)
		return true, S("Available commands: @1", table.concat(cmds, " ")) .. "\n" .. S("Use '@1help <cmd>' to get more information, or '@1help all' to list everything.", cmd_marker)
	elseif param == "all" then
		local cmds = {}
		for cmd, def in pairs(core.registered_chatcommands) do
			if INIT == "client" or core.check_player_privs(name, def.privs) then
				cmds[#cmds + 1] = enhanced_builtin_commands.format_help_line(cmd, def)
			end
		end
		table.sort(cmds)
		return true, S("Available commands: @1", "\n"..table.concat(cmds, "\n"))
	elseif INIT == "game" and param == "privs" then
		local privs = {}
		for priv, def in pairs(core.registered_privileges) do
			privs[#privs + 1] = priv .. ": " .. def.description
		end
		table.sort(privs)
		return true, S("Available privileges:\n@1", table.concat(privs, "\n"))
	else
		local cmd = param
		local def = core.registered_chatcommands[cmd]
		if not def then
			return false, S("Command not available: @1", cmd)
		else
			return true, enhanced_builtin_commands.format_help_line(cmd, def)
		end
	end
end
