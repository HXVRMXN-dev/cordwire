fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'HXVRMXN.dev & OfficialBadger'
description 'DiscordAcePerms and Discord API modernized into one'
version '1.1.0'
url 'https://github.com/HXVRMXN-dev/cordwire'

server_scripts {
	'config.lua',
	'server/http.lua',
	'server/discord.lua',
	'server/permissions.lua',
	'server/commands.lua',
	'server/connectcard.lua',
	'server/main.lua',
}

server_exports {
	'GetDiscordId',
	'GetDiscordUsername',
	'GetDiscordAvatar',
	'GetDiscordEmail',
	'IsDiscordVerified',
	'GetDiscordNickname',
	'SetDiscordNickname',
	'GetUserRoles',
	'GetAllUserRoles',
	'HasRole',
	'ResolveRoleId',
	'AddDiscordRole',
	'RemoveDiscordRole',
	'SetDiscordRoles',
	'GetGuildInfo',
	'GetGuildRoleList',
	'SyncPlayerPermissions',
	'ClearPlayerPermissions',
	'GetPlayerGroups',
	'ClearCache',
}