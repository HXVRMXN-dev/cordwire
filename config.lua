Config = {}

-- your bot's token
Config.Bot = {
	token = '',
	guild = '',
}

-- got roles spread across more than one discord? add them here.
Config.Guilds = {
	-- support = '111111111111111111',
}

Config.Cache = {
	roles       = true, -- cache a player's role list instead of hitting discord every check
	roleSeconds = 300,  -- how long that cache lives, in seconds
}

Config.Perms = {
	enabled   = true,   -- turn the whole ace group sync on/off
	baseGroup = false, -- every player with a linked discord gets this, set to false to skip it
}

-- roles that get thrown out before anything downstream ever sees them.
Config.IgnoredRoles = {
	-- 'Server Booster',
}

--[[

   name     the role's name in discord (case sensitive), skip this if you're using id
   id       the role's snowflake id, skips the name lookup entirely, use whichever you have
   group    the ace group this role hands out. letters/numbers/underscore/dash/dot
            only - anything else gets rejected at sync time instead of silently
            running
   guild    optional, only set this if the role lives in one of Config.Guilds above
   override true means holding this role WIPES every other match this player has,
            even ones they'd otherwise qualify for. good for a "Muted" or
            "Under Investigation" role so a punished VIP doesn't keep VIP perks
            just because discord still shows them holding the role.
            only the first override a player has (top to bottom) is used.
     order doesn't matter except for overrides, list is checked top to bottom either way
--]]
Config.Roles = {
	{ name = 'Owner',     group = 'owner' },
	{ name = 'Admin',     group = 'admin' },
	{ name = 'Moderator', group = 'mod' },
	{ name = 'VIP',       group = 'vip' },

	{ name = 'Muted', group = 'muted', override = true },
}

-- lets a player type /roles (or whatever you rename it to) and see what roles they have currently
Config.Command = {
	enabled = true,
	name    = 'roles',
}

-- /sync (or whatever you rename it to) forces resync
Config.Sync = {
	enabled = true,
	name    = 'sync',

	-- set to false to skip the ace check entirely (role-only)
	ace = 'cordwire.resync',

	-- discord role name(s)/id(s) that also grant access, regardless of ace
	roles = {
		-- 'Admin',
	},

	-- allows for /sync <server id> to be used
	allowTarget = true,
}

Config.ConnectCard = {
	enabled = false,

	-- how long (in seconds) the card holds a connecting player
	holdSeconds = 8,

	-- if true, the player has to click the continue button
	requireContinue = false,
	continueLabel   = 'Continue',

	title       = 'Welcome',  -- big line at the top, blank to skip
	subtitle    = '',         -- smaller line under the title, blank to skip
	body        = '',         -- normal paragraph text, blank to skip
	headerImage = '',         -- banner image url above the text, blank to skip

	-- buttons across the bottom, in order. label + url, add or remove as many as you want.
	buttons = {
		-- { label = 'Discord', url = 'https://discord.gg/yourinvite' },
		-- { label = 'Website', url = 'https://example.com' },
	},
}

Config.Debug = false
