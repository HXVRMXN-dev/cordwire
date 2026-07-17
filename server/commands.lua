local COLOR = {
	ok   = { 80, 220, 120 },
	warn = { 235, 190, 60 },
	err  = { 235, 80, 80 },
	info = { 110, 170, 235 },
}


local function bullet(label, detail)
	if detail and detail ~= '' then
		return (' ^7• ^0%s ^7(^5%s^7)'):format(label, detail)
	end
	return (' ^7• ^0%s'):format(label)
end

local function notify(src, kind, title, lines)
	local body = type(lines) == 'table' and table.concat(lines, '\n') or lines
	TriggerClientEvent('chat:addMessage', src, {
		color     = COLOR[kind] or COLOR.info,
		multiline = true,
		args      = { title, body },
	})
end

local function pluralize(n, word)
	return n == 1 and word or (word .. 's')
end


local function registerSuggestions(target)
	if Config.Command.enabled then
		TriggerClientEvent('chat:addSuggestion', target, '/' .. Config.Command.name,
			'shows which discord roles you match and what ace group each grants')
	end

	if Config.Sync.enabled then
		local params = nil
		if Config.Sync.allowTarget then
			params = { { name = 'id', help = 'server id to sync instead of yourself (optional)' } }
		end
		TriggerClientEvent('chat:addSuggestion', target, '/' .. Config.Sync.name,
			'force a resync against discord, bypassing the role cache', params)
	end
end

CreateThread(function() registerSuggestions(-1) end)
AddEventHandler('playerJoining', function() registerSuggestions(source) end)

-- === /roles ==================================================================

if Config.Command.enabled then
	RegisterCommand(Config.Command.name, function(src)
		if src == 0 then return end -- console isn't a player, nothing to look up

		local discordId = GetDiscordId(src)
		if not discordId then
			notify(src, 'err', '^1Roles', "couldn't find a discord identifier on your account - make sure discord is linked to fivem")
			return
		end

		local roleMap = GetActiveRoleMap(src)
		local matched, _, overrideName = MatchConfigRoles(roleMap)

		if overrideName then
			notify(src, 'warn', '^3Roles', {
				("^0overridden by ^5%s^0:"):format(overrideName),
				' ^7• ^0every other matched role is being ignored while that override is active',
			})
			return
		end

		if #matched == 0 then
			notify(src, 'warn', '^3Roles', 'none of your discord roles are mapped to anything here')
			return
		end

		local lines = { ("^0matched against ^2%d^0 %s:"):format(#matched, pluralize(#matched, 'entry')) }
		for _, entry in ipairs(matched) do
			table.insert(lines, bullet(entry.name, entry.group))
		end

		notify(src, 'ok', '^2Roles', lines)
	end, false)
end

-- === /sync ====================================================================

if Config.Sync.enabled then
	local function hasSyncAccess(src)
		if Config.Sync.ace and IsPlayerAceAllowed(src, Config.Sync.ace) then
			return true
		end

		if Config.Sync.roles and #Config.Sync.roles > 0 then
			for _, role in ipairs(Config.Sync.roles) do
				if HasRole(src, role) then return true end
			end
		end

		return false
	end

	local function runSync(requestedBy, targetSrc, announceToTarget)
		local discordId = GetDiscordId(targetSrc)
		if not discordId then
			notify(requestedBy, 'err', '^1Sync', "that player doesn't have a discord identifier linked, nothing to sync")
			return
		end

		ClearCache(discordId) -- drop the cached role list so this actually hits discord instead of returning stale data
		local granted = SyncPlayerPermissions(targetSrc)

		local lines
		if #granted == 0 then
			lines = 'pulled fresh roles from discord, but nothing matched Config.Roles'
		else
			lines = { ('^0pulled fresh roles from discord, ^2%d^0 %s applied:'):format(#granted, pluralize(#granted, 'group')) }
			for _, group in ipairs(granted) do
				table.insert(lines, bullet(group))
			end
		end

		notify(requestedBy, 'ok', '^2Sync', lines)

		if announceToTarget and targetSrc ~= requestedBy then
			notify(targetSrc, 'info', '^5Sync', 'an admin just resynced your discord roles')
		end
	end

	RegisterCommand(Config.Sync.name, function(src, args)
		if src ~= 0 and not hasSyncAccess(src) then
			notify(src, 'err', '^1Sync', "you don't have permission to run this - needs the cordwire.sync ace perm or an allowed discord role")
			return
		end

		local targetSrc = src
		if args[1] then
			if not Config.Sync.allowTarget then
				notify(src, 'err', '^1Sync', 'targeting another player is disabled - Config.Sync.allowTarget is false')
				return
			end

			local requested = tonumber(args[1])
			if not requested or not GetPlayerName(requested) then
				notify(src, 'err', '^1Sync', ("no player online with server id ^5%s"):format(tostring(args[1])))
				return
			end
			targetSrc = requested
		elseif src == 0 then
			notify(src, 'err', '^1Sync', 'console has to target a player: sync <server id>')
			return
		end

		runSync(src, targetSrc, true)
	end, false)
end