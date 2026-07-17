AddEventHandler('playerJoining', function()
	local src = source
	if Config.Perms.enabled then
		SyncPlayerPermissions(src)
	end
end)

exports('GetDiscordId', GetDiscordId)
exports('GetDiscordUsername', GetDiscordUsername)
exports('GetDiscordAvatar', GetDiscordAvatar)
exports('GetDiscordEmail', GetDiscordEmail)
exports('IsDiscordVerified', IsDiscordVerified)
exports('GetDiscordNickname', GetDiscordNickname)
exports('SetDiscordNickname', SetDiscordNickname)
exports('GetUserRoles', GetUserRoles)
exports('GetAllUserRoles', GetAllUserRoles)
exports('HasRole', HasRole)
exports('ResolveRoleId', ResolveRoleId)
exports('AddDiscordRole', AddDiscordRole)
exports('RemoveDiscordRole', RemoveDiscordRole)
exports('SetDiscordRoles', SetDiscordRoles)
exports('GetGuildInfo', GetGuildInfo)
exports('GetGuildRoleList', GetGuildRoleList)
exports('SyncPlayerPermissions', SyncPlayerPermissions)
exports('ClearPlayerPermissions', ClearPlayerPermissions)
exports('GetPlayerGroups', GetPlayerGroups)
exports('ClearCache', ClearCache)

CreateThread(function()
	if Config.Bot.token == '' or Config.Bot.guild == '' then
		print('^1[cordwire]^7 bot token or guild id missing in config.lua - nothing works until that\'s set')
	end
end)
