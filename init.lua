--[[
A mod that enhances the builtin commands: adds support for intllib, and more.
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

-- Load support for intllib.
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

enhanced_builtin_commands = {
	intllib = S
}

dofile(MP.."/functions.lua")

core.override_chatcommand("admin", {
	description = S("Show the name of the server owner"),
	params = S("<playername>"),
	func = function(name, param)
		local admin = core.settings:get("name")
		if admin and param == "" then
			return true, S("The administrator of this server is @1.", admin)
		elseif not admin then
			if param ~= "" then
			core.chat_send_player(param, S("There's no administrator named in the config file."))
			end
			return false, S("There's no administrator named in the config file.")
		elseif core.check_player_privs(name, {server = true}) then
			core.chat_send_player(param, S("The administrator of this server is @1.", admin))
			core.chat_send_player(name, S("Sent to @1.", param))
		else
			return false, S("You don't have permission to run this command (missing privilege: server).")
		end
	end,
})

core.override_chatcommand("mods", {
	params = S("<playername>"),
	description = S("List mods installed on the server."),
	privs = {},
	func = function(name, param)
		if param == "" then
			return true, table.concat(minetest.get_modnames(), ", ")
		elseif core.check_player_privs(name, {server = true}) then
			core.chat_send_player(param, table.concat(minetest.get_modnames(), ", "))
			core.chat_send_player(name, S("Sent to @1.", param))
		else
			return false, S("You don't have permission to run this command (missing privilege: server).")	
		end
	end,
})

core.override_chatcommand("pulverize", {
	params = S("<playername>"),
	description = S("Destroy item in hand"),
	func = function(name, param)
		local player = core.get_player_by_name(name)
		if not player then
			core.log("error", "Unable to pulverize, no player.")
			return false, S("Unable to pulverize, no player.")
		end
		local wielded_item = player:get_wielded_item()
		if param == "" then
			if wielded_item:is_empty() then
				return false, S("Unable to pulverize, no item in hand.")
			end
			core.log("action", name .. " pulverized \"" ..
				wielded_item:get_name() .. " " .. wielded_item:get_count() .. "\"")
			player:set_wielded_item(nil)
			return true, S("An item was pulverized.")
		elseif core.check_player_privs(name, {server = true}) then
			if core.get_player_by_name(param):get_wielded_item():is_empty() then
				core.chat_send_player(name, S("Unable to pulverize, no item in @1's hand.", param))
			end
			core.log("action", name .. " pulverized \"" ..
				core.get_player_by_name(param):get_wielded_item():get_name() .. " " .. core.get_player_by_name(param):get_wielded_item():get_count() .. "\" from " .. param .. "")
			if not core.get_player_by_name(param):get_wielded_item():is_empty() then
				core.get_player_by_name(param):set_wielded_item(nil)
				core.chat_send_player(param, S("An item was pulverized by @1.", name))
				core.chat_send_player(name, S("Sent to @1.", param))
			end
		else
			return false, S("You don't have permission to run this command (missing privilege: server).")
		end
	end,
})

core.override_chatcommand("status", {
	description = S("Show server status"),
	params = S("<playername>"),
	func = function(name, param)
		local status = core.get_server_status(name, false)
		if param == "" then
			if status and status ~= "" then
				return true, status
			end
		elseif core.check_player_privs(name, {server = true}) then
			core.chat_send_player(param, core.get_server_status(param, false))
			core.chat_send_player(name, S("Sent to @1.", param))
		elseif not status then
			return false, S("This command was disabled by a mod or game")
		else
			return false, S("You don't have permission to run this command (missing privilege: server).")
		end
	end,
})

core.override_chatcommand("days", {
	description = S("Show day count since world creation"),
	func = function(name, param)
		if param == "" then
			return true, S("Current day is @1", core.get_day_count())
		elseif core.check_player_privs(name, {server = true}) then
			core.chat_send_player(param, S("Current day is @1", core.get_day_count()))
			core.chat_send_player(name, S("Sent to @1.", param))
		else
			return false, S("You don't have permission to run this command (missing privilege: server).")
		end
	end
})

core.override_chatcommand("me", {
	params = S("<action>"),
	description = S("Show chat action (e.g., '/me orders a pizza' displays '<player name> orders a pizza')"),
	privs = {shout = true},
	func = function(name, param)
		core.chat_send_all("* " .. name .. " " .. param)
	end,
})

core.override_chatcommand("privs", {
	params = S("[<name>]"),
	description = S("Show privileges of yourself or another player"),
	func = function(caller, param)
		param = param:trim()
		local name = (param ~= "" and param or caller)
		if not core.player_exists(name) then
			return false, S("Player @1 does not exist.", name)
		end
		return true, S("Privileges of @1: @2", name, core.privs_to_string(core.get_player_privs(name), ' '))
	end,
})

core.override_chatcommand("haspriv", {
	params = S("<privilege>"),
	description = S("Return list of all online players with privilege."),
	privs = {basic_privs = true},
	func = function(caller, param)
		param = param:trim()
		if param == "" then
			return false, S("Invalid parameters (see /help haspriv)")
		end
		if not core.registered_privileges[param] then
			return false, S("Unknown privilege!")
		end
		local privs = core.string_to_privs(param)
		local players_with_priv = {}
		for _, player in pairs(core.get_connected_players()) do
			local player_name = player:get_player_name()
			if core.check_player_privs(player_name, privs) then
				table.insert(players_with_priv, player_name)
			end
		end	
		return true, S("Players online with the '@1' privilege: @2", param, table.concat(players_with_priv, ", "))
	end	
})

core.override_chatcommand("grant", {
	params = S("<name> (<privilege> | all)"),
	description = S("Give privileges to player"),
	func = function(name, param)
		local grantname, grantprivstr = string.match(param, "([^ ]+) (.+)")
		if not grantname or not grantprivstr then
			return false, S("Invalid parameters (see /help grant)")
		end
		return enhanced_builtin_commands.grant_command(name, grantname, grantprivstr)
	end,
})

core.override_chatcommand("grantme", {
	params = S("<privilege> | all"),
	description = S("Grant privileges to yourself"),
	func = function(name, param)
		if param == "" then
			return false, S("Invalid parameters (see /help grantme)")
		end
		return enhanced_builtin_commands.grant_command(name, name, param)
	end,
})

core.override_chatcommand("revoke", {
	params = S("<name> (<privilege> | all)"),
	description = S("Remove privileges from player"),
	privs = {},
	func = function(name, param)
		if not core.check_player_privs(name, {privs=true}) and
				not core.check_player_privs(name, {basic_privs=true}) then
			return false, S("Your privileges are insufficient.")
		end
		local revoke_name, revoke_priv_str = string.match(param, "([^ ]+) (.+)")
		if not revoke_name or not revoke_priv_str then
			return false, S("Invalid parameters (see /help revoke)")
		elseif not core.get_auth_handler().get_auth(revoke_name) then
			return false, S("Player @1 does not exist.", revoke_name)
		end
		local revoke_privs = core.string_to_privs(revoke_priv_str)
		local privs = core.get_player_privs(revoke_name)
		local basic_privs =
			core.string_to_privs(core.settings:get("basic_privs") or "interact,shout")
		for priv, _ in pairs(revoke_privs) do
			if not basic_privs[priv] and
					not core.check_player_privs(name, {privs = true}) then
				return false, S("Your privileges are insufficient.")
			end
		end
		if revoke_priv_str == "all" then
			revoke_privs = privs
			privs = {}
		else
			for priv, _ in pairs(revoke_privs) do
				privs[priv] = nil
			end
		end

		for priv, _ in pairs(revoke_privs) do
			core.run_priv_callbacks(revoke_name, priv, name, "revoke")
		end

		core.set_player_privs(revoke_name, privs)
		core.log("action", name..' revoked ('
				..core.privs_to_string(revoke_privs, ', ')
				..') privileges from '..revoke_name)
		if revoke_name ~= name then
			core.chat_send_player(revoke_name, S("@1 revoked privileges from you: @2", name, core.privs_to_string(revoke_privs, ' ')))
		end
		return true, S("Privileges of @1: @2", revoke_name, core.privs_to_string(core.get_player_privs(revoke_name), ' '))
	end,
})

core.override_chatcommand("setpassword", {
	params = S("<name> <password>"),
	description = S("Set player's password"),
	privs = {password = true},
	func = function(name, param)
		local toname, raw_password = string.match(param, "^([^ ]+) +(.+)$")
		if not toname then
			toname = param:match("^([^ ]+) *$")
			raw_password = nil
		end
		if not toname then
			return false, S("Name field required")
		end
		local act_str_past = "?"
		local act_str_pres = "?"
		if not raw_password then
			core.set_player_password(toname, "")
			act_str_past = "cleared"
			act_str_pres = "clears"
		else
			core.set_player_password(toname,
					core.get_password_hash(toname,
							raw_password))
			act_str_past = "set"
			act_str_pres = "sets"
		end
		if toname ~= name then
			core.chat_send_player(toname, S("Your password was @1 by @2", act_str_past, name))
		end

		core.log("action", name .. " " .. act_str_pres
		.. " password of " .. toname .. ".")

		return true, S("Password of player \"@1\"@2 ", toname, act_str_past)
	end,
})

core.override_chatcommand("clearpassword", {
	params = S("<name>"),
	description = S("Set empty password for a player"),
	privs = {password = true},
	func = function(name, param)
		local toname = param
		if toname == "" then
			return false, S("Name field required")
		end
		core.set_player_password(toname, '')

		core.log("action", name .. " clears password of " .. toname .. ".")

		return true, S("Password of player \"@1\" cleared", toname)
	end,
})

core.override_chatcommand("auth_reload", {
	params = "",
	description = S("Reload authentication data"),
	privs = {server = true},
	func = function(name, param)
		local done = core.auth_reload()
		return done, (done and S("Done.") or S("Failed."))
	end,
})

core.override_chatcommand("remove_player", {
	params = S("<name>"),
	description = S("Remove a player's data"),
	privs = {server = true},
	func = function(name, param)
		local toname = param
		if toname == "" then
			return false, S("Name field required")
		end

		local rc = core.remove_player(toname)

		if rc == 0 then
			core.log("action", name .. " removed player data of " .. toname .. ".")
			return true, S("Player '@1' removed.", toname)
		elseif rc == 1 then
			return true, S("No such player '@1' to remove.", toname)
		elseif rc == 2 then
			return true, S("Player '@1' is connected, cannot remove.", toname)
		end

		return false, S("Unhandled remove_player return code @1", rc)
	end,
})

core.override_chatcommand("teleport", {
	params = S("<X>,<Y>,<Z> | <to_name> | (<name> <X>,<Y>,<Z>) | (<name> <to_name>)"),
	description = S("Teleport to position or player"),
	privs = {teleport = true},
	func = function(name, param)
		-- Returns (pos, true) if found, otherwise (pos, false)
		local function find_free_position_near(pos)
			local tries = {
				{x=1,y=0,z=0},
				{x=-1,y=0,z=0},
				{x=0,y=0,z=1},
				{x=0,y=0,z=-1},
			}
			for _, d in ipairs(tries) do
				local p = {x = pos.x+d.x, y = pos.y+d.y, z = pos.z+d.z}
				local n = core.get_node_or_nil(p)
				if n and n.name then
					local def = core.registered_nodes[n.name]
					if def and not def.walkable then
						return p, true
					end
				end
			end
			return pos, false
		end

		local teleportee = nil
		local p = {}
		p.x, p.y, p.z = string.match(param, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
		p.x = tonumber(p.x)
		p.y = tonumber(p.y)
		p.z = tonumber(p.z)
		if p.x and p.y and p.z then
			local lm = 31000
			if p.x < -lm or p.x > lm or p.y < -lm or p.y > lm or p.z < -lm or p.z > lm then
				return false, S("Cannot teleport out of map bounds!")
			end
			teleportee = core.get_player_by_name(name)
			if teleportee then
				teleportee:set_pos(p)
				return true, S("Teleporting to @1.", core.pos_to_string(p))
			end
		end

		local teleportee = nil
		local p = nil
		local target_name = nil
		target_name = param:match("^([^ ]+)$")
		teleportee = core.get_player_by_name(name)
		if target_name then
			local target = core.get_player_by_name(target_name)
			if target then
				p = target:get_pos()
			end
		end
		if teleportee and p then
			p = find_free_position_near(p)
			teleportee:set_pos(p)
			return true, S("Teleporting to @1 at @2", target_name, core.pos_to_string(p))
		end

		if not core.check_player_privs(name, {bring=true}) then
			return false, S("You don't have permission to teleport other players (missing bring privilege)")
		end

		local teleportee = nil
		local p = {}
		local teleportee_name = nil
		teleportee_name, p.x, p.y, p.z = param:match(
				"^([^ ]+) +([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
		p.x, p.y, p.z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
		if teleportee_name then
			teleportee = core.get_player_by_name(teleportee_name)
		end
		if teleportee and p.x and p.y and p.z then
			teleportee:set_pos(p)
			return true, S("Teleporting @1 to @2", teleportee_name, core.pos_to_string(p))
		end

		local teleportee = nil
		local p = nil
		local teleportee_name = nil
		local target_name = nil
		teleportee_name, target_name = string.match(param, "^([^ ]+) +([^ ]+)$")
		if teleportee_name then
			teleportee = core.get_player_by_name(teleportee_name)
		end
		if target_name then
			local target = core.get_player_by_name(target_name)
			if target then
				p = target:get_pos()
			end
		end
		if teleportee and p then
			p = find_free_position_near(p)
			teleportee:set_pos(p)
			return true, S("Teleporting @1 to @2 at @3", teleportee_name, target_name, core.pos_to_string(p))
		end

		return false, S("Invalid parameters ('@1') or player not found (see /help teleport)", param)
	end,
})

core.override_chatcommand("set", {
	params = S("([-n] <name> <value>) | <name>"),
	description = S("Set or read server configuration setting"),
	privs = {server = true},
	func = function(name, param)
		local arg, setname, setvalue = string.match(param, "(-[n]) ([^ ]+) (.+)")
		if arg and arg == "-n" and setname and setvalue then
			core.settings:set(setname, setvalue)
			return true, setname .. " = " .. setvalue
		end
		local setname, setvalue = string.match(param, "([^ ]+) (.+)")
		if setname and setvalue then
			if not core.settings:get(setname) then
				return false, S("Failed. Use '/set -n <name> <value>' to create a new setting.")
			end
			core.settings:set(setname, setvalue)
			return true, S("@1 = @2", setname, setvalue)
		end
		local setname = string.match(param, "([^ ]+)")
		if setname then
			local setvalue = core.settings:get(setname)
			if not setvalue then
				setvalue = S("<not set>")
			end
			return true, S("@1 = @2", setname, setvalue)
		end
		return false, S("Invalid parameters (see /help set).")
	end,
})

core.override_chatcommand("emergeblocks", {
	params = S("(here [<radius>]) | (<pos1> <pos2>)"),
	description = S("Load (or, if nonexistent, generate) map blocks contained in area pos1 to pos2 (<pos1> and <pos2> must be in parentheses)"),
	privs = {server = true},
	func = function(name, param)
		local p1, p2 = enhanced_builtin_commands.parse_range_str(name, param)
		if p1 == false then
			return false, p2
		end

		local context = {
			current_blocks = 0,
			total_blocks   = 0,
			start_time     = os.clock(),
			requestor_name = name
		}

		core.emerge_area(p1, p2, enhanced_builtin_commands.emergeblocks_callback, context)
		core.after(2, enhanced_builtin_commands.emergeblocks_progress_update, context)

		return true, S("Started emerge of area ranging from @1 to @2", core.pos_to_string(p1, 1), core.pos_to_string(p2, 1))
	end,
})

core.override_chatcommand("deleteblocks", {
	params = S("(here [<radius>]) | (<pos1> <pos2>)"),
	description = S("Delete map blocks contained in area pos1 to pos2 (<pos1> and <pos2> must be in parentheses)"),
	privs = {server = true},
	func = function(name, param)
		local p1, p2 = enhanced_builtin_commands.parse_range_str(name, param)
		if p1 == false then
			return false, p2
		end

		if core.delete_area(p1, p2) then
			return true, S("Successfully cleared area ranging from @1 to @2", core.pos_to_string(p1, 1), ore.pos_to_string(p2, 1))
		else
			return false, S("Failed to clear one or more blocks in area")
		end
	end,
})

core.override_chatcommand("fixlight", {
	params = S("(here [<radius>]) | (<pos1> <pos2>)"),
	description = S("Resets lighting in the area between pos1 and pos2 (<pos1> and <pos2> must be in parentheses)"),
	privs = {server = true},
	func = function(name, param)
		local p1, p2 = enhanced_builtin_commands.parse_range_str(name, param)
		if p1 == false then
			return false, p2
		end

		if core.fix_light(p1, p2) then
			return true, S("Successfully reset light in the area ranging from @1 to @2", core.pos_to_string(p1, 1), core.pos_to_string(p2, 1))
		else
			return false, S("Failed to load one or more blocks in area")
		end
	end,
})

core.override_chatcommand("give", {
	params = S("<name> <ItemString> [<count> [<wear>]]"),
	description = S("Give item to player"),
	privs = {give = true},
	func = function(name, param)
		local toname, itemstring = string.match(param, "^([^ ]+) +(.+)$")
		if not toname or not itemstring then
			return false, S("Name and ItemString required")
		end
		return enhanced_builtin_commands.handle_give_command("/give", name, toname, itemstring)
	end,
})

core.override_chatcommand("giveme", {
	params = S("<ItemString> [<count> [<wear>]]"),
	description = S("Give item to yourself"),
	privs = {give = true},
	func = function(name, param)
		local itemstring = string.match(param, "(.+)$")
		if not itemstring then
			return false, S("ItemString required")
		end
		return enhanced_builtin_commands.handle_give_command("/giveme", name, name, itemstring)
	end,
})

core.override_chatcommand("spawnentity", {
	params = S("<EntityName> [<X>,<Y>,<Z>]"),
	description = S("Spawn entity at given (or your) position"),
	privs = {give = true, interact = true},
	func = function(name, param)
		local entityname, p = string.match(param, "^([^ ]+) *(.*)$")
		if not entityname then
			return false, S("EntityName required")
		end
		core.log("action", ("%s invokes /spawnentity, entityname=%q")
				:format(name, entityname))
		local player = core.get_player_by_name(name)
		if player == nil then
			core.log("error", "Unable to spawn entity, player is nil")
			return false, S("Unable to spawn entity, player is nil")
		end
		if not core.registered_entities[entityname] then
			return false, S("Cannot spawn an unknown entity")
		end
		if p == "" then
			p = player:get_pos()
		else
			p = core.string_to_pos(p)
			if p == nil then
				return false, S("Invalid parameters ('@1')", param)
			end
		end
		p.y = p.y + 1
		core.add_entity(p, entityname)
		return true, S("@1 spawned.", entityname)
	end,
})

core.override_chatcommand("rollback_check", {
	params = S("[<range>] [<seconds>] [<limit>]"),
	description = S("Check who last touched a node or a node near it within the time specified by <seconds>. Default: range = 0, seconds = 86400 = 24h, limit = 5"),
	privs = {rollback = true},
	func = function(name, param)
		if not core.settings:get_bool("enable_rollback_recording") then
			return false, S("Rollback functions are disabled.")
		end
		local range, seconds, limit =
			param:match("(%d+) *(%d*) *(%d*)")
		range = tonumber(range) or 0
		seconds = tonumber(seconds) or 86400
		limit = tonumber(limit) or 5
		if limit > 100 then
			return false, S("That limit is too high!")
		end

		core.rollback_punch_callbacks[name] = function(pos, node, puncher)
			local name = puncher:get_player_name()
			core.chat_send_player(name, S("Checking @1...", core.pos_to_string(pos)))
			local actions = core.rollback_get_node_actions(pos, range, seconds, limit)
			if not actions then
				core.chat_send_player(name, S("Rollback functions are disabled."))
				return
			end
			local num_actions = #actions
			if num_actions == 0 then
				core.chat_send_player(name, S("Nobody has touched the specified location in @1 seconds", seconds))
				return
			end
			local time = os.time()
			for i = num_actions, 1, -1 do
				local action = actions[i]
				core.chat_send_player(name,
					S(("%s %s %s -> %s %d seconds ago.")
						:format(
							core.pos_to_string(action.pos),
							action.actor,
							action.oldnode.name,
							action.newnode.name,
							time - action.time)))
			end
		end

		return true, S("Punch a node (range=@1, seconds=@2s, limit=@3)", range, seconds, limit)
	end,
})

core.override_chatcommand("rollback", {
	params = S("(<name> [<seconds>]) | (:<actor> [<seconds>])"),
	description = S("Revert actions of a player. Default for <seconds> is 60"),
	privs = {rollback = true},
	func = function(name, param)
		if not core.settings:get_bool("enable_rollback_recording") then
			return false, S("Rollback functions are disabled.")
		end
		local target_name, seconds = string.match(param, ":([^ ]+) *(%d*)")
		if not target_name then
			local player_name = nil
			player_name, seconds = string.match(param, "([^ ]+) *(%d*)")
			if not player_name then
				return false, S("Invalid parameters. See /help rollback and /help rollback_check.")
			end
			target_name = "player:"..player_name
		end
		seconds = tonumber(seconds) or 60
		core.chat_send_player(name, S("Reverting actions of @1 since @2 seconds.", target_name, seconds))
		local success, log = core.rollback_revert_actions_by(
				target_name, seconds)
		local response = ""
		if #log > 100 then
			response = S("(log is too long to show)\n")
		else
			for _, line in pairs(log) do
				response = response .. line .. "\n"
			end
		end
		response = response .. S("Reverting actions @1", (success and "succeeded." or "FAILED."), success)
		return success, response
	end,
})

core.override_chatcommand("shutdown", {
	params = S("[<delay_in_seconds> | -1] [reconnect] [<message>]"),
	description = S("Shutdown server (-1 cancels a delayed shutdown)"),
	privs = {server = true},
	func = function(name, param)
		local delay, reconnect, message
		delay, param = param:match("^%s*(%S+)(.*)")
		if param then
			reconnect, param = param:match("^%s*(%S+)(.*)")
		end
		message = param and param:match("^%s*(.+)") or ""
		delay = tonumber(delay) or 0

		if delay == 0 then
			core.log("action", name .. " shuts down server")
			core.chat_send_all("*** Server shutting down (operator request).")
		end
		core.request_shutdown(message:trim(), core.is_yes(reconnect), delay)
	end,
})

core.override_chatcommand("ban", {
	params = S("[<name> | <IP_address>]"),
	description = S("Ban player or show ban list"),
	privs = {ban = true},
	func = function(name, param)
		if param == "" then
			local ban_list = core.get_ban_list()
			if ban_list == "" then
				return true, S("The ban list is empty.")
			else
				return true, S("Ban list: @1", ban_list)
			end
		end
		if not core.get_player_by_name(param) then
			return false, S("No such player.")
		end
		if not core.ban_player(param) then
			return false, S("Failed to ban player.")
		end
		local desc = core.get_ban_description(param)
		core.log("action", name .. " bans " .. desc .. ".")
		return true, S("Banned @1.", desc)
	end,
})

core.override_chatcommand("unban", {
	params = S("<name> | <IP_address>"),
	description = S("Remove player ban"),
	privs = {ban = true},
	func = function(name, param)
		if not core.unban_player_or_ip(param) then
			return false, S("Failed to unban player/IP.")
		end
		core.log("action", name .. " unbans " .. param)
		return true, S("Unbanned @1.", param)
	end,
})

core.override_chatcommand("kick", {
	params = S("<name> [<reason>]"),
	description = S("Kick a player"),
	privs = {kick = true},
	func = function(name, param)
		local tokick, reason = param:match("([^ ]+) (.+)")
		tokick = tokick or param
		if not core.kick_player(tokick, reason) then
			return false, S("Failed to kick player @1.", tokick)
		end
		local log_reason = ""
		if reason then
			log_reason = " with reason \"" .. reason .. "\""
		end
		core.log("action", name .. " kicks " .. tokick .. log_reason)
		return true, S("Kicked @1.", tokick)
	end,
})

core.override_chatcommand("clearobjects", {
	params = S("[full | quick]"),
	description = S("Clear all objects in world"),
	privs = {server = true},
	func = function(name, param)
		local options = {}
		if param == "" or param == "quick" then
			options.mode = "quick"
		elseif param == "full" then
			options.mode = "full"
		else
			return false, S("Invalid usage, see /help clearobjects.")
		end

		core.log("action", name .. " clears all objects ("
				.. options.mode .. " mode).")
		core.chat_send_all(S("Clearing all objects. This may take long. You may experience a timeout (by @1).", name))
		core.clear_objects(options)
		core.log("action", "Object clearing done.")
		core.chat_send_all(S("*** Cleared all objects."))
	end,
})

core.override_chatcommand("msg", {
	params = S("<name> <message>"),
	description = S("Send a private message."),
	privs = {shout = true},
	func = function(name, param)
		local sendto, message = param:match("^(%S+)%s(.+)$")
		if not sendto then
			return false, S("Invalid usage, see /help msg.")
		end
		if not core.get_player_by_name(sendto) then
			return false, S("The player @1 is not online.", sendto)
		end
		core.log("action", "PM from " .. name .. " to " .. sendto
				.. ": " .. message)
		core.chat_send_player(sendto, S("PM from @1: @2", name, message))
		return true, S("Message sent.")
	end,
})

core.override_chatcommand("last-login", {
	params = S("[<name>]"),
	description = S("Get the last login time of a player or yourself."),
	func = function(name, param)
		if param == "" then
			param = name
		end
		local pauth = core.get_auth_handler().get_auth(param)
		if pauth and pauth.last_login then
			-- Time in UTC, ISO 8601 format
			return true, S("Last login time was @1", os.date("!%Y-%m-%dT%H:%M:%SZ", pauth.last_login))
		end
		return false, S("Last login time is unknown.")
	end,
})

core.override_chatcommand("clearinv", {
	params = S("[<name>]"),
	description = S("Clear the inventory of yourself or another player."),
	func = function(name, param)
		local player
		if param and param ~= "" and param ~= name then
			if not core.check_player_privs(name, {server = true}) then
				return false, S("You don't have permission to clear another player's inventory (missing privilege: server)")
			end
			player = core.get_player_by_name(param)
			core.chat_send_player(param, S("@1 cleared your inventory.", name))
		else
			player = core.get_player_by_name(name)
		end

		if player then
			player:get_inventory():set_list("main", {})
			player:get_inventory():set_list("craft", {})
			player:get_inventory():set_list("craftpreview", {})
			core.log("action", name.." clears "..player:get_player_name().."'s inventory")
			return true, S("Cleared @1's inventory.", player:get_player_name())
		else
			return false, S("Player must be online to clear inventory!")
		end
	end,
})

core.override_chatcommand("kill", {
	params = S("[<name>]"),
	description = S("Kill player or yourself."),
	privs = {server = true},
	func = function(name, param)
		return enhanced_builtin_commands.handle_kill_command(name, param == "" and name or param)
	end,
})

if INIT == "client" then
	core.override_chatcommand("help", {
		params = S("[all | <cmd>]"),
		description = S("Get help for commands"),
		func = function(param)
			return enhanced_builtin_commands.do_help_cmd(nil, param)
		end,
	})
else
	core.override_chatcommand("help", {
		params = S("[all | privs | <cmd>]"),
		description = S("Get help for commands or list privileges"),
		func = enhanced_builtin_commands.do_help_cmd,
	})
end

-- Minetest Game commands
if minetest.get_modpath("sethome") then
	core.override_chatcommand("home", {
		description = S("Teleport you to your home point"),
		privs = {home = true},
		func = function(name)
			if sethome.go(name) then
				return true, S("Teleported to home!")
			end
			return false, S("Set a home using /sethome")
		end,
	})

	core.override_chatcommand("sethome", {
		description = S("Set your home point"),
		privs = {home = true},
		func = function(name)
			name = name or "" -- fallback to blank name if nil
			local player = core.get_player_by_name(name)
			if player and sethome.set(name, player:get_pos()) then
				return true, S("Home set!")
			end
			return false, S("Player not found!")
		end,
	})
		else
	return
end
