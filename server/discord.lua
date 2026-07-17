-- core discord lookups. a chunk of this traces back to Badger's
-- Badger_Discord_API (MIT), rewritten for caching + config. see LICENSE-MIT / NOTICE.

Cache = {
	avatars = {},
	roles = {},
	guildRoles = {},
	guilds = {},
}

local function dbg(msg)
	if Config.Debug then
		print(('^3[cordwire]^7 %s'):format(msg))
	end
end

-- server-side identifiers aren't spoofable the way a client-sent value would
-- be, but a discord snowflake is always digits, so enforce that shape anyway
-- before it goes anywhere near a console command (see permissions.lua)
local function discordIdFor(src)
	for _, id in ipairs(GetPlayerIdentifiers(src)) do
		if id:find('discord:') then
			local stripped = id:gsub('discord:', '')
			if stripped:match('^%d+$') then
				return stripped
			end
			return nil
		end
	end
	return nil
end

local function guildId(key)
	if key and Config.Guilds[key] then
		return tostring(Config.Guilds[key])
	end
	return tostring(Config.Bot.guild)
end

function GetDiscordId(src)
	return discordIdFor(src)
end

function GetGuildRoleList(guildKey)
	local gid = guildId(guildKey)
	if Cache.guildRoles[gid] then
		return Cache.guildRoles[gid]
	end

	local res = DiscordRequest('GET', 'guilds/' .. gid, nil)
	if res.code ~= 200 then
		dbg('failed to fetch role list for guild ' .. gid .. ' (' .. tostring(res.code) .. ')')
		return {}
	end

	local data = json.decode(res.data)
	local list = {}
	for _, role in ipairs(data.roles) do
		list[role.name] = role.id
	end

	Cache.guildRoles[gid] = list
	SetTimeout(300000, function() Cache.guildRoles[gid] = nil end)
	return list
end

-- role id, a name from Config.Roles, or a raw guild role name - always
-- returns a string id or nil
function ResolveRoleId(role, guildKey)
	if role == nil then return nil end
	if tonumber(role) and tostring(role):match('^%d+$') then
		return tostring(role)
	end

	for _, entry in ipairs(Config.Roles) do
		if entry.name == role and entry.id then
			return tostring(entry.id)
		end
	end

	local list = GetGuildRoleList(guildKey)
	return list[role] and tostring(list[role]) or nil
end

function GetUserRoles(src, guildKey)
	local id = discordIdFor(src)
	if not id then return {} end
	local gid = guildId(guildKey)

	if Config.Cache.roles and Cache.roles[id] and Cache.roles[id][gid] then
		return Cache.roles[id][gid]
	end

	local res = DiscordRequest('GET', ('guilds/%s/members/%s'):format(gid, id), nil)
	if res.code ~= 200 then
		return {}
	end

	local roles = json.decode(res.data).roles or {}

	if Config.Cache.roles then
		Cache.roles[id] = Cache.roles[id] or {}
		Cache.roles[id][gid] = roles
		SetTimeout(Config.Cache.roleSeconds * 1000, function()
			if Cache.roles[id] then Cache.roles[id][gid] = nil end
		end)
	end

	return roles
end

function GetAllUserRoles(src)
	local combined = {}
	for _, roleId in ipairs(GetUserRoles(src)) do
		table.insert(combined, roleId)
	end
	for key in pairs(Config.Guilds) do
		for _, roleId in ipairs(GetUserRoles(src, key)) do
			table.insert(combined, roleId)
		end
	end
	return combined
end

function HasRole(src, role, guildKey)
	local rid = ResolveRoleId(role, guildKey)
	if not rid then return false end
	for _, r in ipairs(GetAllUserRoles(src)) do
		if tostring(r) == rid then return true end
	end
	return false
end

function GetDiscordAvatar(src)
	local id = discordIdFor(src)
	if not id then return nil end
	if Cache.avatars[id] then return Cache.avatars[id] end

	local res = DiscordRequest('GET', 'users/' .. id, nil)
	if res.code ~= 200 then return nil end

	local data = json.decode(res.data)
	if not data.avatar then return nil end

	local ext = data.avatar:sub(1, 2) == 'a_' and '.gif' or '.png'
	local url = 'https://cdn.discordapp.com/avatars/' .. id .. '/' .. data.avatar .. ext
	Cache.avatars[id] = url
	return url
end

function GetDiscordUsername(src)
	local id = discordIdFor(src)
	if not id then return nil end

	local res = DiscordRequest('GET', 'users/' .. id, nil)
	if res.code ~= 200 then return nil end

	local data = json.decode(res.data)
	if data.discriminator == '0' or data.discriminator == 0 then
		return data.username
	end
	return data.username .. '#' .. data.discriminator
end

function GetDiscordEmail(src)
	local id = discordIdFor(src)
	if not id then return nil end

	local res = DiscordRequest('GET', 'users/' .. id, nil)
	if res.code ~= 200 then return nil end
	return json.decode(res.data).email
end

function IsDiscordVerified(src)
	local id = discordIdFor(src)
	if not id then return false end

	local res = DiscordRequest('GET', 'users/' .. id, nil)
	if res.code ~= 200 then return false end
	return json.decode(res.data).verified == true
end

function GetDiscordNickname(src, guildKey)
	local id = discordIdFor(src)
	if not id then return nil end

	local res = DiscordRequest('GET', ('guilds/%s/members/%s'):format(guildId(guildKey), id), nil)
	if res.code ~= 200 then return nil end
	return json.decode(res.data).nick
end

function SetDiscordNickname(src, nickname, reason)
	local id = discordIdFor(src)
	if not id then return false end

	local res = DiscordRequest('PATCH', ('guilds/%s/members/%s'):format(guildId(), id), { nick = nickname or '' }, reason)
	return res.code == 200 or res.code == 204
end

-- single-role PUT/DELETE instead of fetch-then-overwrite-the-whole-list.
-- fewer requests, no chance of clobbering a role that got added mid-fetch
function AddDiscordRole(src, role, reason)
	local id = discordIdFor(src)
	if not id then return false end
	local rid = ResolveRoleId(role)
	if not rid then return false end

	local res = DiscordRequest('PUT', ('guilds/%s/members/%s/roles/%s'):format(guildId(), id, rid), nil, reason)
	if res.code == 200 or res.code == 204 then
		if Cache.roles[id] then Cache.roles[id][guildId()] = nil end
		return true
	end
	return false
end

function RemoveDiscordRole(src, role, reason)
	local id = discordIdFor(src)
	if not id then return false end
	local rid = ResolveRoleId(role)
	if not rid then return false end

	local res = DiscordRequest('DELETE', ('guilds/%s/members/%s/roles/%s'):format(guildId(), id, rid), nil, reason)
	if res.code == 200 or res.code == 204 then
		if Cache.roles[id] then Cache.roles[id][guildId()] = nil end
		return true
	end
	return false
end

function SetDiscordRoles(src, roleList, reason)
	local id = discordIdFor(src)
	if not id then return false end

	local resolved = {}
	for _, r in ipairs(roleList) do
		local rid = ResolveRoleId(r)
		if rid then table.insert(resolved, rid) end
	end

	local res = DiscordRequest('PATCH', ('guilds/%s/members/%s'):format(guildId(), id), { roles = resolved }, reason)
	if res.code == 200 then
		if Cache.roles[id] then Cache.roles[id][guildId()] = nil end
		return true
	end
	return false
end

function GetGuildInfo(guildKey)
	local gid = guildId(guildKey)
	if Cache.guilds[gid] then return Cache.guilds[gid] end

	local res = DiscordRequest('GET', 'guilds/' .. gid .. '?with_counts=true', nil)
	if res.code ~= 200 then return nil end

	local data = json.decode(res.data)
	local info = {
		id = data.id,
		name = data.name,
		description = data.description,
		memberCount = data.approximate_member_count,
		onlineCount = data.approximate_presence_count,
		icon = data.icon and ('https://cdn.discordapp.com/icons/' .. gid .. '/' .. data.icon
			.. (data.icon:sub(1, 2) == 'a_' and '.gif' or '.png')) or nil,
	}

	Cache.guilds[gid] = info
	SetTimeout(300000, function() Cache.guilds[gid] = nil end)
	return info
end

function ClearCache(discordId)
	if discordId then
		Cache.roles[discordId] = nil
		Cache.avatars[discordId] = nil
	else
		Cache = { avatars = {}, roles = {}, guildRoles = {}, guilds = {} }
	end
end
