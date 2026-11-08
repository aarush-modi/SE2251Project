-- FR-08 / BR-14: non-personal usage analytics. Each visit gets a random session token;
-- player names and IP addresses are never written. Log: <world>/weve_analytics.csv
local log_path = weve.worldpath .. "/weve_analytics.csv"
local sessions = {}

local function token()
	local t = {}
	for i = 1, 12 do t[i] = string.format("%x", math.random(0, 15)) end
	return table.concat(t)
end

local function write(sess, event, target)
	local f = io.open(log_path, "a")
	if not f then return end
	f:write(string.format("%s,%s,%s,%s\n", os.date("!%Y-%m-%dT%H:%M:%SZ"), sess, event, target or ""))
	f:close()
end

do -- header once
	local f = io.open(log_path, "r")
	if f then f:close() else
		f = io.open(log_path, "w")
		if f then f:write("utc_time,session,event,target\n") f:close() end
	end
end

math.randomseed(os.time())

function weve.track(player, event, target)
	local name = player and player:get_player_name()
	local sess = name and sessions[name]
	if sess then write(sess, event, target) end
end

minetest.register_on_joinplayer(function(player)
	local s = token()
	sessions[player:get_player_name()] = s
	write(s, "session_start", "")
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if sessions[name] then write(sessions[name], "session_end", "") end
	sessions[name] = nil -- token discarded on logout
end)

minetest.register_chatcommand("weve_stats", {
	description = "Show anonymous usage counts (operators only)",
	privs = {server = true},
	func = function()
		local f = io.open(log_path, "r")
		if not f then return true, "No analytics yet." end
		local counts, sess = {}, {}
		for line in f:lines() do
			local _, s, ev, tg = line:match("^([^,]*),([^,]*),([^,]*),(.*)$")
			if s and ev ~= "event" then
				local k = ev .. (tg ~= "" and (" " .. tg) or "")
				counts[k] = (counts[k] or 0) + 1
				sess[s] = true
			end
		end
		f:close()
		local n = 0
		for _ in pairs(sess) do n = n + 1 end
		local lines = {"Sessions: " .. n}
		local keys = {}
		for k in pairs(counts) do keys[#keys + 1] = k end
		table.sort(keys)
		for _, k in ipairs(keys) do lines[#lines + 1] = k .. ": " .. counts[k] end
		return true, table.concat(lines, "\n")
	end,
})
