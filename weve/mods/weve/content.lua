-- FR-07 / BR-13: all visible text, image names and links come from one JSON file.
-- A copy in the world folder (weve_content.json) overrides the one shipped with the mod,
-- so staff can edit content without touching code or the map. Restart to apply.
local function read_file(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local s = f:read("*a")
	f:close()
	return s
end

function weve.load_content()
	local src = weve.worldpath .. "/weve_content.json"
	local raw = read_file(src)
	if not raw then
		src = weve.modpath .. "/content/weve_content.json"
		raw = read_file(src)
	end
	local data = raw and minetest.parse_json(raw)
	if type(data) ~= "table" or type(data.pois) ~= "table" then
		minetest.log("error", "[weve] could not read content from " .. tostring(src))
		data = {pois = {}, tour = {}, buildings = {}}
	end
	local keep = {}
	for id, p in pairs(weve.pois) do keep[id] = {pos = p.pos, yaw = p.yaw} end
	weve.pois, weve.poi_order = {}, {}
	for _, p in ipairs(data.pois) do
		if type(p.id) == "string" then
			p.links = type(p.links) == "table" and p.links or {}
			if keep[p.id] then p.pos, p.yaw = keep[p.id].pos, keep[p.id].yaw end
			weve.pois[p.id] = p
			table.insert(weve.poi_order, p.id)
		end
	end
	weve.tour = type(data.tour) == "table" and data.tour or weve.poi_order
	weve.buildings = type(data.buildings) == "table" and data.buildings or {}
	minetest.log("action", "[weve] loaded " .. #weve.poi_order .. " points of interest from " .. src)
end

weve.load_content()
