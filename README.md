# cordwire

lightweight discord role/perm bridge for fivem. config is one file and it's meant to be readable in under a
minute.

## setup

1. drop this folder anywhere in your resources, name it whatever you want
2. open `config.lua`, fill in `Config.Bot.token` and `Config.Bot.guild`
3. fill out `Config.Roles` with your actual discord role names and the ace
   groups you want them to grant
4. `ensure cordwire` in server.cfg, above anything that depends on ace 
   groups being set to avoid any issues
5. at the bottom of server.cfg, put `add_ace resource.cordwire command.add_principal allow`
   and `add_ace resource.cordwire command.remove_principal allow` so ace perms can be given

swap `cordwire` for whatever you actually named the folder.


## config quick reference

- `Config.Guilds` — only needed if you check roles across more than one server
- `Config.IgnoredRoles` — roles that get thrown out before perms or `/roles` ever see them
- `Config.Roles[].override` — set true on something like "Muted" so it wipes every
  other match a player has, even roles they still technically hold
- `Config.Command` and `Config.Sync`  — toggles the `/roles` and `sync` command, renameable

## exports

```lua
exports.cordwire:GetDiscordId(src)
exports.cordwire:GetDiscordUsername(src)
exports.cordwire:GetDiscordAvatar(src)
exports.cordwire:GetDiscordNickname(src, guildKey)
exports.cordwire:HasRole(src, roleNameOrId, guildKey)
exports.cordwire:GetAllUserRoles(src)
exports.cordwire:AddDiscordRole(src, roleNameOrId, reason)
exports.cordwire:RemoveDiscordRole(src, roleNameOrId, reason)
exports.cordwire:SetDiscordRoles(src, { 'Role One', 'Role Two' }, reason)
exports.cordwire:GetGuildInfo(guildKey)
exports.cordwire:SyncPlayerPermissions(src)
exports.cordwire:GetPlayerGroups(src)
```

swap `cordwire` for whatever you actually named the folder.

> [!NOTE]
If you have any suggestions, bugs or any kind of issues, then make a issue on the repository.
This section will be updated if I open a discord.

>[!CAUTION]
This repository uses dual licenses, make sure to read them!

![Views](https://komarev.com/ghpvc/?username=HXVRMXN-dev&repo=cordwire&color=blue)
