-- discord roles -> ace principals. Config.Roles.override lets one role act
-- as a floor that wipes everything else out (Muted, w/e).

local granted = {}

-- discord snowflakes are digits only. anything else touching ExecuteCommand
-- below is a command injection waiting to happen (space/semicolon/newline in
-- there and you've just run whatever came after it in console), so this is
-- non-negotiable, not just cleanup
local function isSafeId(id)
	return type(id) == 'string' and id:match('^%d+$') ~= nil
end

-- group names come from config.lua so a server owner controls them, but
-- validate anyway - one careless space in a group name in config.lua
-- shouldn't be able to turn into "add_principal identifier.discord:123 mod;
-- <anything>". alnum/underscore/dash/dot only, same as ace normally expects
local function isSafeGroup(group)
	return type(group) == 'string' and group:match('^[%w_%.%-]+$') ~= nil
end

local function stripPrincipals(discordId)
	local list = granted[discordId]
	if not list then return end

	for _, group in ipairs(list) do
		ExecuteCommand(('remove_principal identifier.discord:%s %s'):format(discordId, group))
	end
	granted[discordId] = nil
end

local function applyGroup(discordId, group)
	if not isSafeId(discordId) then
		print('^1[cordwire]^7 refused to apply a group, discord id looked wrong: ' .. tostring(discordId))
		return
	end
	if not isSafeGroup(group) then
		print(('^1[cordwire]^7 refused to apply group "%s" - check Config.Roles, group names are alnum/underscore/dash/dot only'):format(tostring(group)))
		return
	end

	ExecuteCommand(('add_principal identifier.discord:%s %s'):format(discordId, group))
	granted[discordId] = granted[discordId] or {}
	table.insert(granted[discordId], group)
end

-- pulls a player's raw role ids down to just what's mapped/relevant, minus
-- anything in Config.IgnoredRoles. commands.lua uses this too so /roles shows
-- the same picture perms actually acted on
function GetActiveRoleMap(src)
	local map = {}
	for _, rid in ipairs(GetAllUserRoles(src)) do
		map[tostring(rid)] = true
	end

	for _, raw in ipairs(Config.IgnoredRoles) do
		local rid = ResolveRoleId(raw)
		if rid then map[rid] = nil end
	end

	return map
end

function MatchConfigRoles(roleMap)
	local matched, overrideGroup, overrideName = {}, nil, nil

	for _, entry in ipairs(Config.Roles) do
		local rid = ResolveRoleId(entry.id or entry.name, entry.guild)
		if rid and roleMap[rid] then
			if entry.override then
				-- first one wins, top to bottom, if someone somehow holds two override roles
				if not overrideGroup then
					overrideGroup = entry.group
					overrideName = entry.name
				end
			else
				table.insert(matched, entry)
			end
		end
	end

	return matched, overrideGroup, overrideName
end

function SyncPlayerPermissions(src)
	if not Config.Perms.enabled then return {} end

	local discordId = GetDiscordId(src)
	if not discordId then return {} end
	if not isSafeId(discordId) then return {} end -- shouldn't happen, but see isSafeId above for why we don't trust it blind

	stripPrincipals(discordId)

	local roleMap = GetActiveRoleMap(src)
	local matched, overrideGroup = MatchConfigRoles(roleMap)

	if Config.Perms.baseGroup then
		applyGroup(discordId, Config.Perms.baseGroup)
	end

	if overrideGroup then
		applyGroup(discordId, overrideGroup)
	else
		for _, entry in ipairs(matched) do
			applyGroup(discordId, entry.group)
		end
	end

	return granted[discordId] or {}
end

function ClearPlayerPermissions(src)
	local discordId = GetDiscordId(src)
	if discordId then stripPrincipals(discordId) end
end

function GetPlayerGroups(src)
	local discordId = GetDiscordId(src)
	if not discordId then return {} end
	return granted[discordId] or {}
end

AddEventHandler('playerDropped', function()
	ClearPlayerPermissions(source)
end)
