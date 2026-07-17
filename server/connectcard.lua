if not Config.ConnectCard.enabled then return end

local function textBlock(text, size, weight)
	return {
		type   = 'TextBlock',
		text   = text,
		wrap   = true,
		size   = size,
		weight = weight or 'Default',
		color  = 'Light',
	}
end

local function buildCard()
	local items = {}

	if Config.ConnectCard.title ~= '' then
		table.insert(items, textBlock(Config.ConnectCard.title, 'ExtraLarge', 'Bolder'))
	end
	if Config.ConnectCard.subtitle ~= '' then
		table.insert(items, textBlock(Config.ConnectCard.subtitle, 'Large', 'Bolder'))
	end
	if Config.ConnectCard.body ~= '' then
		table.insert(items, textBlock(Config.ConnectCard.body, 'Medium'))
	end

	local actions = {}
	for _, btn in ipairs(Config.ConnectCard.buttons) do
		if btn.url and btn.url ~= '' then
			table.insert(actions, {
				type  = 'Action.OpenUrl',
				title = btn.label or 'Link',
				url   = btn.url,
				style = 'positive',
			})
		end
	end
	if Config.ConnectCard.requireContinue then
		table.insert(actions, {
			type  = 'Action.Submit',
			title = Config.ConnectCard.continueLabel,
			style = 'positive',
			id    = 'continue',
		})
	end
	if #actions > 0 then
		table.insert(items, { type = 'ActionSet', actions = actions })
	end

	local body = {}
	if Config.ConnectCard.headerImage ~= '' then
		table.insert(body, { type = 'Image', url = Config.ConnectCard.headerImage, horizontalAlignment = 'Center' })
	end
	table.insert(body, { type = 'Container', items = items, style = 'default', bleed = true })

	return json.encode({
		type      = 'AdaptiveCard',
		['$schema'] = 'http://adaptivecards.io/schemas/adaptive-card.json',
		version   = '1.2',
		body      = body,
	})
end

local cachedCard = nil
CreateThread(function() cachedCard = buildCard() end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
	deferrals.defer()
	Wait(0)

	-- give buildCard's thread a tick to have run at least once, in the
	-- unlikely case a player connects in the same frame the resource starts
	while not cachedCard do Wait(0) end

	local continued = false
	local seconds = 0
	local holdSeconds = math.max(1, Config.ConnectCard.holdSeconds or 1)

	while true do
		deferrals.presentCard(cachedCard, function(data, rawData)
			if data and data.submitId == 'continue' then
				continued = true
			end
		end)

		Wait(1000)
		seconds = seconds + 1

		if Config.ConnectCard.requireContinue then
			if continued then break end
		elseif seconds >= holdSeconds then
			break
		end
	end

	deferrals.done()
end)