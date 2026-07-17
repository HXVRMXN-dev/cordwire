-- everything that talks to discord goes through this queue instead of firing
-- requests straight off. keeps a wave of people connecting at once from
-- blowing through discord's rate limit and getting the whole bot timed out

local botToken = nil
local queue = {}
local inFlight = 0
local maxInFlight = 4

CreateThread(function()
	botToken = 'Bot ' .. tostring(Config.Bot.token)
	-- token only ever lives in this local + the Authorization header below.
	-- don't print botToken anywhere, even behind Config.Debug
end)

local function encodeBody(body)
	if body == nil then return '' end
	if type(body) == 'table' then
		if next(body) == nil then return '' end
		return json.encode(body)
	end
	return body
end

local function pump()
	if inFlight >= maxInFlight then return end
	local job = table.remove(queue, 1)
	if not job then return end

	inFlight = inFlight + 1
	PerformHttpRequest('https://discord.com/api/v10/' .. job.endpoint, function(code, data, headers)
		inFlight = inFlight - 1

		if code == 429 then
			local retryAfter = 1200
			if headers and headers['Retry-After'] then
				retryAfter = math.ceil(tonumber(headers['Retry-After']) * 1000)
			end
			table.insert(queue, 1, job)
			SetTimeout(retryAfter, pump)
			return
		end

		job.resolve({ code = code, data = data, headers = headers })
		pump()
	end, job.method, job.body, {
		['Content-Type'] = 'application/json',
		['Authorization'] = botToken,
		['X-Audit-Log-Reason'] = job.reason or '',
	})
end

function DiscordRequest(method, endpoint, body, reason)
	local p = promise.new()
	table.insert(queue, {
		method = method,
		endpoint = endpoint,
		body = encodeBody(body),
		reason = reason,
		resolve = function(result) p:resolve(result) end,
	})
	pump()
	return Citizen.Await(p)
end
