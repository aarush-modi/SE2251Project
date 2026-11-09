-- Building generator. Block-based digital twins at 1 block = 1 m (NFR-09).
--
-- Sources
--   * SEB, CMLP and ACEB: Western Facilities Management floor plans SEB-01 to SEB-05 (2024),
--     drawn at 1/16" = 1'-0" (available only to Western students and staff; not included in this package). site_data.lua keeps only the
--     outline of every level (per 1 m cell). The tour spaces below follow the same plans; room
--     numbers are given in the comments.
--   * TEB is not in the plan set. Its north end and the bridge (TA.235) are on SEB-03, which fixes
--     its position and its 23 m width; its 100 m length is still an estimate from the satellite view.
--
-- Plan level 02 (rooms 1xxx) is the floor you walk in on, so it is the ground floor here.
-- Levels 03, 04 and 05 are floors 2, 3 and 4. Level 01 is a lower level and is not modelled.
--
-- World axes: x = east, z = north (plan "building north" is to the right of the sheet), y = up.
-- Ground surface y = -1; visitors stand at y = 0. Storey k has its floor slab at y = 4k - 1.
local N = "weve_nodes:"
dofile(weve.modpath .. "/site_data.lua")
local SITE = weve.SITE

-- TEB is built from a parametric shell; ACEB uses a local frame for its interior. ------------------
-- lx runs along the entrance facade (left to right seen from outside), lz from that facade inwards.
local BUILDINGS = {
	teb = {name = "Thompson Engineering Building", short = "TEB", ox = 31, oz = 11, rot = "W", W = 100, D = 23, F = 4, cx = 18,
		wall = N .. "limestone", trim = N .. "sandstone_trim", win = N .. "glass", period = 4, wincols = {[1] = true, [2] = true},
		lobby = {half = 7, depth = 7, floor = N .. "tile", label = "Main lobby"},
		corridor = {width = 3, floor = N .. "tile", label = "Main corridor"},
		show = {key = "lab", label = "ECE teaching lab", dx = 2, w = 14, depth = 9, floor = N .. "tile", door = 2}},
	-- ACEB: 89 x 27 m (SEB-02). Courtyard (east) facade is lz = 0; Western Road facade is lz = 26.
	-- lx 0 is the far (south) end; lx 88 is the wall shared with SEB. The atrium hall TA.144 is lx 78..87.
	aceb = {name = "Amit Chakma Engineering Building", short = "ACEB", ox = -24, oz = -73, rot = "E", W = 89, D = 27, F = 4, cx = 80},
	seb = {name = "Spencer Engineering Building", short = "SEB"},
}
local HUB = {x0 = -18, x1 = 22, z0 = -12, z1 = 12}
local REGION_MIN = {x = -100, y = -8, z = -100}
local REGION_MAX = {x = 95, y = 34, z = 150}

-- Local -> world transforms ----------------------------------------------------------------
-- rot = side of the building the entrance faces. k = facedir rotation, yr = yaw offset.
local ROT = {
	S = {k = 0, yr = 0,               f = function(b, lx, lz) return b.ox + lx, b.oz + lz end},
	E = {k = 3, yr = math.pi / 2,     f = function(b, lx, lz) return b.ox - lz, b.oz + lx end},
	N = {k = 2, yr = math.pi,         f = function(b, lx, lz) return b.ox - lx, b.oz - lz end},
	W = {k = 1, yr = 3 * math.pi / 2, f = function(b, lx, lz) return b.ox + lz, b.oz - lx end},
}
local function to_world(b, lx, y, lz)
	local x, z = ROT[b.rot].f(b, lx, lz)
	return {x = x, y = y, z = z}
end
local function rect_world(b, lx0, lx1, lz0, lz1)
	local a, c = to_world(b, lx0, 0, lz0), to_world(b, lx1, 0, lz1)
	return math.min(a.x, c.x), math.max(a.x, c.x), math.min(a.z, c.z), math.max(a.z, c.z)
end
local function yaw_to(from, to)   -- Luanti yaw: 0 looks north (+z), pi/2 looks west (-x)
	return math.atan2(-(to.x - from.x), to.z - from.z) % (2 * math.pi)
end

-- Derived geometry for the parametric TEB -------------------------------------------------------
local teb, aceb = BUILDINGS.teb, BUILDINGS.aceb
do
	local b = teb
	b.code = "teb"
	b.x0, b.z0, b.x1, b.z1 = 0, 0, b.W - 1, b.D - 1
	b.H = 4 * b.F
	local L, C, S = b.lobby, b.corridor, b.show
	L.x0, L.x1, L.z0, L.z1 = b.cx - L.half, b.cx + L.half, 1, L.depth
	C.wall_s = L.z1 + 1
	C.z0, C.z1 = C.wall_s + 1, C.wall_s + C.width
	C.wall_n = C.z1 + 1
	S.x0 = b.cx + S.dx
	S.x1 = S.x0 + S.w - 1
	S.z0 = C.wall_n + 1
	S.z1 = math.min(S.z0 + S.depth - 1, b.z1 - 1)
	S.door_x = S.x0 + S.door
end
aceb.code = "aceb"
for code, b in pairs(BUILDINGS) do
	weve.buildings[code] = weve.buildings[code] or {name = b.name, short = b.short}
end
weve.BUILDINGS = BUILDINGS

-- ACEB plan geometry (local), from SEB-02 to SEB-05 ------------------------------------------------
local AC = {
	hall = {x0 = 78, x1 = 87},           -- TA.144, full depth lz 1..25, doors EX.18 (lz 0) and EX.24 (lz 26)
	door = {x0 = 79, x1 = 81},
	gal = {z0 = 21, z1 = 25},            -- TA.141 along the Western Road side = Engineering Galleries
	stair1 = {x0 = 69},                  -- glass stair beside EX.24 up to floor 2, lz 21..23, climbing towards the hall
	proto = {x0 = 52, x1 = 64, z0 = 1, z1 = 19, door = 58},   -- room 1440 (about 250 m2 = the 2,500 sq ft space)
	void = {z0 = 8, z1 = 20},            -- open to below on floors 2 and 3 (SEB-03, SEB-04), lx 78..87
	ust = {z0 = 17, z1 = 20},            -- U-shaped stair ST.E, floor 2 -> 3, over the atrium
	stf = {x0 = 75, x1 = 76},            -- ST.F, floor 3 -> 4, in corridor TA.343
}

-- Teleport targets and info points ----------------------------------------------------------
local function stand(b, lx, lz, lyaw)
	local p = to_world(b, lx, 0.5, lz)
	return p, ((lyaw or 0) + ROT[b.rot].yr) % (2 * math.pi)
end
weve.hub_spawn = {pos = {x = 2, y = 0.5, z = -8}, yaw = 0}
weve.lobbies = {}
do
	local p, y = stand(teb, teb.cx, 2, 0)
	weve.lobbies.teb = {pos = p, yaw = y}
	p, y = stand(aceb, 2, 23, 3 * math.pi / 2)                  -- inside the south entrance EX.23, facing ST.B
	weve.lobbies.aceb = {pos = p, yaw = y}
	weve.lobbies.seb = {pos = {x = 5, y = 0.5, z = 107}, yaw = math.pi / 2}   -- inside EX.7, facing the entrance hall
end

local POI_LOCAL = { -- building, node (lx, lz), stand (lx, lz), local yaw
	teb_lobby = {teb, teb.cx - 4, 4, teb.cx - 4, 2, 0},
	teb_corridor = {teb, teb.cx - 10, teb.corridor.z0, teb.cx - 10, teb.corridor.z1, math.pi},
	teb_lab = {teb, teb.show.door_x - 1, teb.show.z0, teb.show.door_x, teb.corridor.z0 + 1, 0},
	aceb_atrium = {aceb, 84, 4, 84, 2, 0},
	aceb_proto = {aceb, AC.proto.door + 3, AC.gal.z0, AC.proto.door + 3, AC.gal.z0 + 2, math.pi},
	aceb_sustain = {aceb, 85, -3, 85, -6, 0},
}
local POI_POS = {hub_welcome = {node = {x = 2, y = 0, z = -4}, stand = {x = 2, y = 0.5, z = -7}, yaw = 0}}
for id, d in pairs(POI_LOCAL) do
	local sp, sy = stand(d[1], d[4], d[5], d[6])
	POI_POS[id] = {node = to_world(d[1], d[2], 0, d[3]), stand = sp, yaw = sy}
end
-- SEB (world coordinates, SEB-02)
for id, d in pairs({
	seb_hall = {node = {x = -8, y = 0, z = 104}, stand = {x = -6, y = 0.5, z = 107}},
	seb_dean = {node = {x = 5, y = 0, z = 115}, stand = {x = 3, y = 0.5, z = 114}},
	seb_classroom = {node = {x = 33, y = 0, z = 114}, stand = {x = 32, y = 0.5, z = 112}},
}) do
	d.yaw = yaw_to(d.stand, d.node)
	POI_POS[id] = d
end
weve.POI_POS = POI_POS
function weve.apply_poi_positions()
	for id, pp in pairs(POI_POS) do
		if weve.pois[id] then weve.pois[id].pos, weve.pois[id].yaw = pp.stand, pp.yaw end
	end
end
weve.apply_poi_positions()

-- HUD zones (FR-05), most specific first -------------------------------------------------------
local function zone(label, x0, x1, z0, z1, building, y0, y1)
	table.insert(weve.zones, {label = label, x0 = x0, x1 = x1, z0 = z0, z1 = z1, y0 = y0 or -2, y1 = y1 or 4, building = building})
end
local function lzone(b, label, lx0, lx1, lz0, lz1, y0, y1)
	local x0, x1, z0, z1 = rect_world(b, lx0, lx1, lz0, lz1)
	zone(label, x0, x1, z0, z1, b.code, y0 or -2, y1)
end
zone("Engineering courtyard - Hub", HUB.x0, HUB.x1, HUB.z0, HUB.z1, "hub", -2, 30)
-- ACEB
lzone(aceb, "ACEB - Floor 4 - Landing above the atrium", 72, 76, 2, 8, 11.5, 16)
lzone(aceb, "ACEB - Floor 3 - Stairs over the atrium (ST.E, ST.F)", 75, 87, 7, 22, 7.5, 11.4)
lzone(aceb, "ACEB - Floor 2 - Atrium gallery", 68, 87, 6, 25, 3.2, 7.4)
lzone(aceb, "ACEB - Ground floor - Prototyping space", AC.proto.x0, AC.proto.x1, AC.proto.z0, AC.proto.z1, -2, 4)
lzone(aceb, "ACEB - Floor 2 - Corridor from the south stair", 13, 67, 22, 25, 3.2, 7.4)
lzone(aceb, "ACEB - Ground floor - South entrance and stair ST.B", -4, 20, 20, 26, -2, 3.4)
lzone(aceb, "ACEB - Ground floor - Engineering Galleries", 0, 77, AC.gal.z0, AC.gal.z1, -2, 3.1)
lzone(aceb, "ACEB - Ground floor - Atrium", AC.hall.x0, AC.hall.x1, 1, 25, -2, 3.1)
lzone(aceb, "ACEB - Ground floor", -4, 88, 0, 26, -2, 3.1)
-- SEB (SEB-02)
zone("SEB - Ground floor - Lecture hall 1200", 29, 48, 116, 130, "seb", -2, 7)
zone("SEB - Ground floor - Lecture-hall lobby (TA.121)", 22, 49, 110, 115, "seb", -2, 3.1)
zone("SEB - Ground floor - Main corridor (TA.101)", -30, 21, 114, 115, "seb", -2, 3.1)
zone("SEB - Ground floor - Corridor TA.103", -11, -10, 109, 113, "seb", -2, 3.1)
zone("SEB - Ground floor - Entrance (EX.7)", -11, 10, 104, 108, "seb", -2, 3.1)
-- every other indoor space, by building and floor (only while you are actually indoors)
local function indoor(pos) return weve.indoor(pos) end
for _, g in ipairs({{"CMLP", "context", 23, 56, 26, 68}, {"ACEB", "aceb", -50, -24, -73, 15}, {"SEB", "seb", -50, 56, 14, 140}}) do
	for k = 1, 5 do
		local yf = 4 * (k - 2) - 1
		local names = {"Basement (Level 01)", "Ground floor", "Floor 2", "Floor 3", "Floor 4"}
		table.insert(weve.zones, {label = g[1] .. " - " .. names[k], x0 = g[3], x1 = g[4], z0 = g[5], z1 = g[6],
			y0 = yf + 0.2, y1 = yf + 4.1, building = g[2], check = indoor})
	end
end
-- TEB
do
	local b = teb
	local pre = b.short .. " - Ground floor - "
	lzone(b, pre .. b.show.label, b.show.x0, b.show.x1, b.show.z0, b.show.z1)
	lzone(b, pre .. b.corridor.label, 1, b.x1 - 1, b.corridor.z0, b.corridor.z1)
	lzone(b, pre .. b.lobby.label, b.lobby.x0, b.lobby.x1, b.lobby.z0, b.lobby.z1)
	lzone(b, b.short .. " - Ground floor", 0, b.x1, 0, b.z1)
end
-- outside
do
	local x0, x1, z0, z1 = rect_world(teb, -6, teb.x1 + 6, -8, teb.z1 + 6)
	zone("Outside the Thompson Engineering Building", x0, x1, z0, z1, "teb_out", -2, 40)
	x0, x1, z0, z1 = rect_world(aceb, -6, 88, -8, 32)
	zone("Outside the Amit Chakma Engineering Building", x0, x1, z0, z1, "aceb_out", -2, 40)
	zone("Outside the Claudette MacKay-Lassonde Pavilion (not part of this tour)", 21, 60, 20, 70, "context", -2, 40)
	zone("Outside the Spencer Engineering Building", -55, 60, 14, 140, "seb_out", -2, 40)
end

-- Voxel helpers. TF = current building (local coordinates), or nil for world coordinates ------------
local vm, area, data, p2
local TF
local cids = {}
local function cid(name)
	local c = cids[name]
	if not c then c = minetest.get_content_id(name) cids[name] = c end
	return c
end
local function wset(x, y, z, name, param2)
	if not area:contains(x, y, z) then return end
	local i = area:index(x, y, z)
	data[i] = cid(name)
	p2[i] = param2 or 0
end
local function set(x, y, z, name, param2)
	if TF then
		local r = ROT[TF.rot]
		local wx, wz = r.f(TF, x, z)
		wset(wx, y, wz, name, ((param2 or 0) + r.k) % 4)
	else
		wset(x, y, z, name, param2)
	end
end
local function getn(x, y, z)
	if TF then x, z = ROT[TF.rot].f(TF, x, z) end
	if not area:contains(x, y, z) then return nil end
	return data[area:index(x, y, z)]
end
local function fill(x0, y0, z0, x1, y1, z1, name, param2)
	for z = math.min(z0, z1), math.max(z0, z1) do
		for y = math.min(y0, y1), math.max(y0, y1) do
			for x = math.min(x0, x1), math.max(x0, x1) do set(x, y, z, name, param2) end
		end
	end
end
local meta_jobs = {}

-- door in a wall that runs along x (param2 0) or along z (param2 1)
local function door(x, z, locked, along_z)
	local r = along_z and 1 or 0
	set(x, 0, z, locked and "weve:door_locked" or "weve:door", r)
	set(x, 1, z, locked and "weve:door_locked_top" or "weve:door_top", r)
	set(x, 2, z, N .. "wall")
end
local function lights(x0, x1, z0, z1, y)
	for x = x0 + 1, x1, 4 do
		for z = z0 + 1, z1, 4 do
			if getn(x, y, z) == cid("air") then set(x, y, z, N .. "light") end
		end
	end
end
local function infopoint(id)
	local pp = POI_POS[id]
	wset(pp.node.x, pp.node.y, pp.node.z, "weve:infopoint")
	table.insert(meta_jobs, {pos = pp.node, id = id})
end
-- a ground-floor room: floor, air up to `top`, ceiling above (current frame)
local function room(x0, x1, z0, z1, floor, top)
	top = top or 2
	fill(x0, -1, z0, x1, -1, z1, floor)
	fill(x0, 0, z0, x1, top, z1, "air")
	fill(x0, top + 1, z0, x1, top + 1, z1, N .. "ceiling")
end
-- Half-height steps. rows = list of rows in climbing order, each a list of {x, z} cells;
-- s0 = standing height before the first step. Row k stands at s0 + 0.5 k.
local function flight(rows, s0, kind)
	for k, row in ipairs(rows) do
		local s = s0 + 0.5 * k
		local y, name
		if s % 1 == 0 then y, name = s, N .. kind .. "_slab" else y, name = s - 0.5, N .. kind .. "_step" end
		for _, c in ipairs(row) do
			set(c[1], y, c[2], name)
			fill(c[1], y + 1, c[2], c[1], y + 3, c[2], "air")
		end
	end
end

-- Every level of the connected buildings, from the floor plans (world coordinates) ----------------
-- Plan level k has its floor slab at y = 4 (k - 2) - 1: Level 01 (basement) -5, Level 02 (ground) -1,
-- Level 03 3, Level 04 7, Level 05 11. Cell codes are listed at the top of site_data.lua.
local LEVELS = {1, 2, 3, 4, 5}
local function floor_y(k) return 4 * (k - 2) - 1 end
weve.floor_y = floor_y
weve.LEVEL_NAMES = {[1] = "Basement (Level 01)", [2] = "Ground floor", [3] = "Floor 2", [4] = "Floor 3", [5] = "Floor 4"}
local function code(k, x, z)
	local row = SITE.levels[k][z - SITE.z0 + 1]
	if not row then return "0" end
	local j = x - SITE.x0 + 1
	if j < 1 or j > SITE.nx then return "0" end
	return row:sub(j, j)
end
weve.site_code = code
local function idc(x, z)
	local row = SITE.id[z - SITE.z0 + 1]
	return row and row:sub(x - SITE.x0 + 1, x - SITE.x0 + 1) or "S"
end
local function solid_here(c) return c == "0" or c == "6" end
-- the level a standing position is on, and whether it is indoors
function weve.level_at(pos) return math.floor((pos.y + 5.5) / 4) + 1 end
function weve.indoor(pos)
	local k = weve.level_at(pos)
	if k < 1 or k > 5 then return false end
	local c = code(k, math.floor(pos.x + 0.5), math.floor(pos.z + 0.5))
	return c == "1" or c == "4" or c == "5" or c == "2"
end
local STYLE = {
	S = {wall = N .. "sandstone", trim = N .. "sandstone_trim", win = N .. "glass", floor = N .. "terrazzo", period = 3, cren = true},
	T = {wall = N .. "sandstone", trim = N .. "sandstone_trim", win = N .. "glass", floor = N .. "terrazzo", period = 3, cren = true},
	C = {wall = N .. "concrete", trim = N .. "concrete", win = N .. "glass", floor = N .. "tile", period = 3},
	A = {wall = N .. "curtain", trim = N .. "concrete_dark", win = N .. "curtain", floor = N .. "terrazzo", period = 1, curtain = true},
}
local function build_levels()
	-- Task 1 scope (Section 4, FR-02, Doc 6): exteriors of every connected building, but only the
	-- approved ground-floor areas are open inside. Everything else stays closed behind the walls,
	-- so the plan outline of every level gives the facade, and the inside is solid.
	for zi = 1, SITE.nz do
		local z = SITE.z0 + zi - 1
		for xi = 1, SITE.nx do
			local x = SITE.x0 + xi - 1
			local st = STYLE[idc(x, z)] or STYLE.S
			local top
			for k = 2, 5 do                                              -- Level 01 is below ground
				local c = code(k, x, z)
				if not solid_here(c) then
					local yf = floor_y(k)
					local face = c == "3"
					set(x, yf, z, face and (k == 2 and N .. "concrete" or st.trim) or N .. "concrete")
					if face then
						local alongx = solid_here(code(k, x, z - 1)) or solid_here(code(k, x, z + 1))
						local coord = alongx and x or z
						for y = yf + 1, yf + 3 do
							set(x, y, z, (st.curtain or (y > yf + 1 and coord % st.period ~= 0)) and st.win or st.wall)
						end
					else
						fill(x, yf + 1, z, x, yf + 3, z, N .. "dark")
					end
					top = k
				end
			end
			if top then
				local yr = floor_y(top) + 4
				local edge = code(top, x, z) == "3"
				set(x, yr, z, edge and st.trim or N .. "concrete")             -- roof
				if st.cren and edge and (x + z) % 2 == 0 then set(x, yr + 1, z, st.trim) end
			end
		end
	end
	-- SEB tower over room 1076 (roof plan SEB-06): rises about 12 m above the roof, crenellated
	local T = {x0 = -26, x1 = -18, z0 = 118, z1 = 127, y0 = 12, y1 = 23}
	for x = T.x0, T.x1 do
		for z = T.z0, T.z1 do
			local edge = x == T.x0 or x == T.x1 or z == T.z0 or z == T.z1
			for y = T.y0, T.y1 do
				local name = N .. "dark"
				if edge then
					local mid = (x == T.x0 or x == T.x1) and (z - T.z0) or (x - T.x0)
					name = ((y - T.y0) % 4 ~= 0 and (mid == 3 or mid == 5)) and N .. "glass" or N .. "sandstone_trim"
				end
				set(x, y, z, name)
			end
			if edge and (x + z) % 2 == 0 then set(x, T.y1 + 1, z, N .. "sandstone_trim") end
		end
	end
end

-- stair markers: choose a floor, arrive at the nearest stair (or floor space) on that level
local function nearest_free(k, x, z, r, need)
	need = need or 3
	local best
	for d = 0, r do
		for dx = -d, d do
			for dz = -d, d do
				local cx, cz = x + dx, z + dz
				local open = 0
				for _, o in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do if code(k, cx + o[1], cz + o[2]) == "1" then open = open + 1 end end
				if math.max(math.abs(dx), math.abs(dz)) == d and code(k, cx, cz) == "1" and open >= need then
					local n = minetest.get_node({x = x + dx, y = floor_y(k) + 1, z = z + dz}).name
					if n == "air" then return {x = x + dx, y = floor_y(k) + 0.5, z = z + dz} end
				end
			end
		end
	end
	return best
end
local function floors_at(x, z)
	local list = {}
	for _, k in ipairs(LEVELS) do
		if nearest_free(k, x, z, 4, 1) then list[#list + 1] = k end
	end
	return list
end
minetest.register_node("weve:stairs", {
	description = "Stairs (right-click to change floor)",
	tiles = {"weve_stairs.png", "weve_infopoint_side.png", "weve_infopoint_side.png"},
	drawtype = "nodebox", paramtype = "light", light_source = 4,
	node_box = {type = "fixed", fixed = {{-0.15, -0.5, -0.15, 0.15, 0.3, 0.15}, {-0.35, 0.3, -0.35, 0.35, 0.5, 0.35}}},
	groups = {not_in_creative_inventory = 1}, diggable = false, is_ground_content = false,
	on_construct = function(pos) minetest.get_meta(pos):set_string("infotext", "Stairs: right-click to change floor") end,
	on_rightclick = function(pos, node, clicker)
		if not clicker or not clicker:is_player() then return end
		local here = weve.level_at({y = pos.y - 0.5})
		local fs = {"formspec_version[4]size[7,8]label[0.4,0.6;Stairs and lifts: choose a floor]"}
		local y = 1.2
		for _, k in ipairs(floors_at(pos.x, pos.z)) do
			if k == here then
				fs[#fs + 1] = ("label[0.6,%.1f;%s (you are here)]"):format(y + 0.4, weve.LEVEL_NAMES[k])
			else
				fs[#fs + 1] = ("button[0.4,%.1f;6.2,0.8;floor_%d;%s]"):format(y, k, weve.LEVEL_NAMES[k])
			end
			y = y + 1.1
		end
		fs[#fs + 1] = ("button_exit[0.4,%.1f;6.2,0.8;close;Stay here]"):format(y + 0.2)
		local name = clicker:get_player_name()
		weve.stairs_ctx = weve.stairs_ctx or {}
		weve.stairs_ctx[name] = {x = pos.x, z = pos.z}
		minetest.show_formspec(name, "weve:stairs", table.concat(fs))
	end,
})
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "weve:stairs" then return end
	local ctx = weve.stairs_ctx and weve.stairs_ctx[player:get_player_name()]
	if not ctx then return true end
	for k = 1, 5 do
		if fields["floor_" .. k] then
			-- prefer a stair marker on the target level within a few metres
			local target
			for _, p in ipairs(SITE.stairs[k] or {}) do
				if math.abs(p[1] - ctx.x) <= 6 and math.abs(p[2] - ctx.z) <= 6 then
					target = nearest_free(k, p[1], p[2], 3) or nearest_free(k, p[1], p[2], 3, 1) break
				end
			end
			target = target or nearest_free(k, ctx.x, ctx.z, 8) or nearest_free(k, ctx.x, ctx.z, 8, 1)
			if target then
				player:set_pos(target)
				if weve.track then weve.track(player, "floor_change", weve.LEVEL_NAMES[k]) end
			end
			minetest.close_formspec(player:get_player_name(), "weve:stairs")
			return true
		end
	end
	return true
end)

-- Site: ground, roads, courtyard hub, paths, trees (world coordinates) ------------------------
local function build_site()
	fill(REGION_MIN.x, REGION_MIN.y + 1, REGION_MIN.z, REGION_MAX.x, -2, REGION_MAX.z, N .. "dirt")
	fill(REGION_MIN.x, -1, REGION_MIN.z, REGION_MAX.x, -1, REGION_MAX.z, N .. "grass")
	fill(REGION_MIN.x, 0, REGION_MIN.z, REGION_MAX.x, REGION_MAX.y, REGION_MAX.z, "air")
	-- Western Road (west) and the service road and parking lot (east)
	fill(-92, -1, REGION_MIN.z, -72, -1, REGION_MAX.z, N .. "asphalt")
	fill(-82, -1, REGION_MIN.z, -82, -1, REGION_MAX.z, N .. "asphalt_line")
	fill(-70, -1, REGION_MIN.z, -65, -1, REGION_MAX.z, N .. "path")      -- Western Road sidewalk
	fill(61, -1, REGION_MIN.z, 70, -1, REGION_MAX.z, N .. "asphalt")
	fill(71, -1, -60, 90, -1, 60, N .. "asphalt")
	for z = -58, 58, 3 do fill(71, -1, z, 76, -1, z, N .. "asphalt_line") fill(85, -1, z, 90, -1, z, N .. "asphalt_line") end
	for z = -20, 20, 4 do set(72, 0, z, N .. "ev_charger", 1) end
	-- courtyard hub between ACEB and TEB
	fill(HUB.x0, -1, HUB.z0, HUB.x1, -1, HUB.z1, N .. "plaza")
	for _, c in ipairs({{HUB.x0, HUB.z0}, {HUB.x1, HUB.z0}, {HUB.x0, HUB.z1}, {HUB.x1, HUB.z1}}) do
		fill(c[1], 0, c[2], c[1], 3, c[2], N .. "purple")
		set(c[1], 4, c[2], N .. "light")
	end
	-- three pads behind the welcome point: ACEB (left, west), SEB (centre, north), TEB (right, east)
	for _, pd in ipairs({{"aceb", -4}, {"seb", 2}, {"teb", 8}}) do
		local code, px = pd[1], pd[2]
		set(px, 0, 2, "weve:portal_" .. code)
		for t = 1, 4 do set(px - 2 + t - 1, 2, 3, N .. "sign_" .. code .. "_" .. t) end
		fill(px - 2, 0, 3, px - 2, 1, 3, N .. "purple")
		fill(px + 1, 0, 3, px + 1, 1, 3, N .. "purple")
	end
	for _, x in ipairs({-12, -9, 13, 16}) do set(x, 0, -10, N .. "bench_seat") end
	for _, x in ipairs({-14, 18}) do set(x, 0, 6, N .. "plant") end
	infopoint("hub_welcome")
	-- paths from the hub to each entrance
	fill(-23, -1, 6, HUB.x0 - 1, -1, 8, N .. "path")          -- ACEB, EX.18
	fill(-22, -1, -86, -20, -1, HUB.z0, N .. "path")          -- ACEB south entrance EX.23: down the courtyard,
	fill(-48, -1, -86, -20, -1, -84, N .. "path")             -- round the south end
	fill(-48, -1, -84, -45, -1, -78, N .. "path")
	fill(HUB.x1 + 1, -1, -8, 30, -1, -6, N .. "path")         -- TEB main entrance
	fill(19, -1, HUB.z1 + 1, 21, -1, 19, N .. "path")          -- SEB: north, east under the bridge,
	fill(19, -1, 17, 59, -1, 19, N .. "path")                  -- up the east side past the Pavilion,
	fill(57, -1, 17, 59, -1, 85, N .. "path")                  -- then west into the SEB courtyard to EX.7
	fill(12, -1, 83, 59, -1, 85, N .. "path")
	fill(12, -1, 83, 14, -1, 105, N .. "path")
	fill(8, -1, 104, 14, -1, 106, N .. "path")
	-- garden in the SEB courtyard (between SEB, the Pavilion and the lecture-hall extension)
	for _, r in ipairs({{18, 50, 74}, {18, 50, 79}, {18, 50, 90}, {18, 26, 96}}) do fill(r[1], 0, r[3], r[2], 0, r[3] + 1, N .. "leaves") end
	-- trees along Western Road, in the courtyards and around the hub
	for _, t in ipairs({{-60, -60}, {-60, -30}, {-60, 0}, {-60, 30}, {-60, 60}, {-60, 90}, {-60, 125},
			{-20, 100}, {-17, 90}, {22, 93}, {40, 77}, {0, -40}, {12, -60}, {-8, 20}, {40, -95}, {-40, -90}}) do
		fill(t[1] - 2, 4, t[2] - 2, t[1] + 2, 6, t[2] + 2, N .. "leaves")
		fill(t[1], 0, t[2], t[1], 4, t[2], N .. "trunk")
	end
	-- all connected buildings, every level, from the plans
	build_levels()
	-- Pavilion stair tower facing TEB: a limestone face with vertical fins and tall window strips (photo)
	local T = {x0 = 38, x1 = 54, z = 27, H = 14}
	for x = T.x0, T.x1 do
		if (x - T.x0) % 3 == 0 then fill(x, 0, T.z - 1, x, T.H, T.z - 1, N .. "sandstone_trim") end    -- fins
		for y = 0, T.H do set(x, y, T.z, ((x - T.x0) % 3 ~= 0 and y % 4 ~= 3 and y > 0) and N .. "curtain" or N .. "sandstone_trim") end
	end
	-- enclosed glass bridge TA.235 from the Pavilion to TEB at floor 2 (SEB-03). The Pavilion is
	-- outside the tour (Doc 6), so the bridge is seen from outside only; the path passes underneath.
	fill(44, 3, 12, 48, 3, 27, N .. "concrete")
	fill(44, 7, 12, 48, 7, 27, N .. "concrete")
	fill(44, 4, 12, 44, 6, 27, N .. "curtain")
	fill(48, 4, 12, 48, 6, 27, N .. "curtain")
	fill(45, 4, 12, 47, 6, 27, "air")
end

-- Parametric building shell and ground-floor plan (TEB, local coordinates) --------------------------
local function build_building(b)
	local x0, x1, z0, z1, H_ = b.x0, b.x1, b.z0, b.z1, b.H
	local L, C, S = b.lobby, b.corridor, b.show
	fill(x0, -1, z0, x1, -1, z1, N .. "concrete")
	for k = 1, b.F do fill(x0, 4 * k - 1, z0, x1, 4 * k - 1, z1, N .. "concrete") end
	for y = 0, H_ - 1 do
		local fy = y % 4
		local wrow = (fy == 1 or fy == 2)
		for x = x0, x1 do
			for _, z in ipairs({z0, z1}) do
				local name = (wrow and b.wincols[(x - x0) % b.period] and x > x0 and x < x1) and b.win or b.wall
				if fy == 3 then name = b.trim end
				set(x, y, z, name)
			end
		end
		for z = z0 + 1, z1 - 1 do
			for _, x in ipairs({x0, x1}) do
				local name = (wrow and b.wincols[(z - z0) % b.period]) and b.win or b.wall
				if fy == 3 then name = b.trim end
				set(x, y, z, name)
			end
		end
	end
	fill(x0 + 1, 4, z0 + 1, x1 - 1, H_ - 2, z1 - 1, N .. "dark")      -- upper floors are not part of the tour
	for k = 1, b.F - 1 do fill(x0 + 1, 4 * k - 1, z0 + 1, x1 - 1, 4 * k - 1, z1 - 1, N .. "concrete") end
	fill(L.x0, -1, L.z0, L.x1, -1, L.z1, L.floor)
	fill(x0 + 1, -1, C.z0, x1 - 1, -1, C.z1, C.floor)
	fill(S.x0, -1, S.z0, S.x1, -1, S.z1, S.floor)
	fill(x0 + 1, 3, C.z0, x1 - 1, 3, C.z1, N .. "ceiling")
	fill(S.x0, 3, S.z0, S.x1, 3, S.z1, N .. "ceiling")
	fill(L.x0, 3, L.z0, L.x1, 3, L.z1, N .. "ceiling")
	fill(L.x0 - 1, 0, z0 + 1, L.x0 - 1, 2, L.z1, N .. "wall")
	fill(L.x1 + 1, 0, z0 + 1, L.x1 + 1, 2, L.z1, N .. "wall")
	fill(x0 + 1, 0, C.wall_s, x1 - 1, 2, C.wall_s, N .. "wall")
	local op = L.opening or 2
	fill(b.cx - op, 0, C.wall_s, b.cx + op, 2, C.wall_s, "air")
	fill(x0 + 1, 0, C.wall_n, x1 - 1, 2, C.wall_n, N .. "wall")
	fill(S.x0 - 1, 0, S.z0, S.x0 - 1, 2, S.z1 + 1, N .. "wall")
	fill(S.x1 + 1, 0, S.z0, S.x1 + 1, 2, S.z1 + 1, N .. "wall")
	if S.z1 + 1 < z1 then fill(S.x0, 0, S.z1 + 1, S.x1, 2, S.z1 + 1, N .. "wall") end
	fill(x0 + 1, 0, z0 + 1, L.x0 - 2, 2, L.z1, N .. "dark")
	fill(L.x1 + 2, 0, z0 + 1, x1 - 1, 2, L.z1, N .. "dark")
	fill(x0 + 1, 0, C.wall_n + 1, S.x0 - 2, 2, z1 - 1, N .. "dark")
	fill(S.x1 + 2, 0, C.wall_n + 1, x1 - 1, 2, z1 - 1, N .. "dark")
	door(S.door_x, C.wall_n, false)
	for x = x0 + 4, x1 - 4, 8 do   -- restricted doors (BR-12)
		if (x < L.x0 - 1 or x > L.x1 + 1) then door(x, C.wall_s, true) end
		if (x < S.x0 - 1 or x > S.x1 + 1) and math.abs(x - b.cx) > op + 1 then door(x, C.wall_n, true) end
	end
	fill(b.cx - 1, 0, z0, b.cx + 1, 2, z0, "air")   -- main entrance
	lights(L.x0, L.x1, L.z0, L.z1, 2)
	lights(x0 + 1, x1 - 1, C.z0, C.z1, 2)
	lights(S.x0, S.x1, S.z0, S.z1, 2)
end

local function details_teb(b)
	local cx, z0, S = b.cx, b.z0, b.show
	for y = 0, b.H - 1 do                                                -- glass entrance section
		for x = cx - 6, cx + 6 do if y % 4 ~= 3 then set(x, y, z0, b.win) end end
	end
	fill(cx - 1, 0, z0, cx + 1, 2, z0, "air")
	for t = 1, 4 do set(cx - 2 + t - 1, 5, z0, N .. "sign_teb_" .. t) end
	fill(cx - 5, 3, z0 - 3, cx + 5, 3, z0 - 1, N .. "concrete")          -- canopy
	for _, x in ipairs({cx + 3, cx + 4, cx + 5}) do set(x, 0, z0 + 5, N .. "bench_seat") end
	set(cx - 6, 0, z0 + 5, N .. "plant") set(cx + 6, 0, z0 + 2, N .. "plant")
	for z = S.z0 + 3, S.z1 - 2, 3 do                                     -- teaching lab
		for x = S.x0 + 1, S.x1 - 1 do
			if (x - S.x0) % 5 ~= 0 then
				set(x, 0, z, N .. "lab_bench")
				if (x - S.x0) % 2 == 0 then set(x, 1, z, N .. "equipment") end
				set(x, 0, z - 1, N .. "stool")
			end
		end
	end
	fill(S.x0 + 2, 1, S.z1, S.x1 - 2, 2, S.z1, N .. "whiteboard", 2)
	fill(S.x0, 0, S.z0 + 1, S.x1, 2, S.z0 + 1, N .. "barrier")          -- doorway view only
	infopoint("teb_lobby") infopoint("teb_corridor") infopoint("teb_lab")
end

-- ACEB interior from the plans (local coordinates, TF = aceb) ---------------------------------------
local function build_aceb()
	local hx0, hx1 = AC.hall.x0, AC.hall.x1
	local G, P, V = AC.gal, AC.proto, AC.void
	-- south entrance EX.23 (SEB-02): glass vestibule TA.140 in front of the south wall, under the
	-- cantilevered floors 3 and 4. Inside is a double-height space with the open glass stair ST.B
	-- to floor 2, a few seconds' walk from the doors.
	fill(-4, -1, 20, -1, -1, 26, N .. "terrazzo")
	fill(-4, 0, 20, -1, 2, 26, N .. "curtain")
	fill(-4, 3, 20, -1, 3, 26, N .. "concrete_dark")
	fill(-3, 0, 21, -1, 2, 25, "air")
	fill(-4, 0, 22, -4, 2, 23, "air")                                              -- EX.23 doors
	for t = 1, 4 do set(-4, 3, 25 - t, N .. "sign_aceb_" .. t, 1) end
	-- entrances EX.18 (courtyard) and EX.24 (Western Road) at the north atrium; sign and canopy over EX.18
	fill(AC.door.x0, 0, 0, AC.door.x1, 2, 0, "air")
	fill(AC.door.x0, 0, 26, AC.door.x1, 2, 26, "air")
	for t = 1, 4 do set(AC.door.x0 - 1 + t - 1, 3, 0, N .. "sign_aceb_" .. t) end
	fill(AC.door.x0 - 1, 3, -3, AC.door.x1 + 1, 3, -1, N .. "concrete_dark")
	-- ground floor: atrium hall TA.144 (full depth), Engineering Galleries TA.141, prototyping space 1440
	room(hx0, hx1, 1, 25, N .. "terrazzo")
	room(0, 77, G.z0, G.z1, N .. "wood")
	-- double-height space by the south entrance (open to below on SEB-03) and ST.B up to floor 2
	fill(0, 3, 22, 20, 6, 25, "air")
	local rows = {}
	for i = 0, 7 do rows[#rows + 1] = {{13 + i, 23}, {13 + i, 24}, {13 + i, 25}} end
	flight(rows, -0.5, "glass")
	-- floor 2 corridor TA.241 along the Western Road side, from the top of ST.B to the north atrium
	fill(21, 4, 22, 77, 6, 25, "air")
	fill(21, 3, 22, 77, 3, 25, N .. "terrazzo")
	lights(0, 20, 22, 25, 6) lights(21, 77, 22, 25, 6)
	-- classrooms along the galleries (closed): 1400, 1410, 1415, 1420, the core, 1450
	for _, x in ipairs({6, 16, 27, 37, 46, 70}) do door(x, G.z0 - 1, true) end
	room(P.x0, P.x1, P.z0, P.z1, N .. "concrete")
	door(P.door, G.z0 - 1, false) door(P.door + 1, G.z0 - 1, false)
	-- atrium: open through floors 2 and 3 over lx 78..87, lz 8..20, under a skylight roof (3 storeys here)
	fill(hx0, 3, V.z0, hx1, 10, V.z1, "air")
	fill(hx0, 3, 1, hx1, 3, 7, N .. "concrete")                                     -- floor 2 over the east rooms
	fill(hx0, 11, 1, hx1, 11, 25, N .. "concrete")
	fill(hx0, 11, V.z0, hx1, 11, V.z1, N .. "glass")                                -- skylight
	-- floor 2: gallery TA.243 above classroom 1450, and the strip TA.244 along the Western Road side
	fill(68, 4, 6, 77, 6, 20, "air")
	fill(68, 4, 21, hx1, 6, 25, "air")
	fill(68, 3, 6, 77, 3, 25, N .. "terrazzo")
	fill(hx0, 3, 21, hx1, 3, 25, N .. "terrazzo")
	fill(77, 4, V.z0, 77, 4, 18, N .. "glass")                                      -- glass balustrades
	fill(hx0, 4, 21, hx1, 4, 21, N .. "glass")
	-- U-shaped stair ST.E over the atrium: up (north) from floor 2, half landing, back (south) to floor 3
	rows = {}
	for i = 0, 3 do rows[#rows + 1] = {{hx0 + i, 19}, {hx0 + i, 20}} end
	flight(rows, 3.5, "glass")
	fill(hx0 + 4, 5, AC.ust.z0, hx0 + 7, 5, AC.ust.z1, N .. "glass_step")
	fill(hx0 + 4, 6, AC.ust.z0, hx0 + 7, 8, AC.ust.z1, "air")
	rows = {}
	for i = 3, 0, -1 do rows[#rows + 1] = {{hx0 + i, 17}, {hx0 + i, 18}} end
	flight(rows, 5.5, "glass")
	fill(hx0 + 4, 6, AC.ust.z0 - 1, hx0 + 7, 6, AC.ust.z0 - 1, N .. "glass")         -- landing balustrades
	fill(hx0 + 8, 6, AC.ust.z0, hx0 + 8, 6, AC.ust.z1, N .. "glass")
	-- floor 3: corridor TA.343 along the south edge of the atrium, with ST.F up to floor 4
	fill(AC.stf.x0, 7, 7, 77, 7, 22, N .. "terrazzo")
	fill(AC.stf.x0, 8, 7, 77, 10, 22, "air")
	fill(77, 8, V.z0, 77, 8, 16, N .. "glass")
	fill(hx0, 7, 21, hx1, 7, 25, N .. "concrete")                                   -- room 3445 above TA.244
	rows = {}
	for i = 0, 7 do rows[#rows + 1] = {{AC.stf.x0, 16 - i}, {AC.stf.x1, 16 - i}} end
	fill(AC.stf.x0, 11, 9, AC.stf.x1, 13, 16, "air")                                -- stairwell through floor 4
	flight(rows, 7.5, "glass")
	-- floor 4 landing. Its north wall (lx 77, curtain wall) lines up with ST.F, so floor 4 never
	--    extends over the atrium; the view is over the skylight roof.
	fill(72, 12, 2, 76, 14, 8, "air")
	fill(72, 11, 2, 76, 11, 8, N .. "terrazzo")
	-- lights
	lights(hx0, hx1, 1, 7, 2) lights(hx0, hx1, 21, 25, 2)
	lights(hx0, hx1, V.z0, V.z1, 10)
	lights(1, 76, G.z0, G.z1, 2)
	lights(P.x0, P.x1, P.z0, P.z1, 2)
	lights(68, 76, 6, 20, 6) lights(72, 76, 2, 8, 14)
	-- furniture: benches and plants in the hall, display cases along the galleries, prototyping space
	for _, x in ipairs({83, 84, 86}) do set(x, 0, 12, N .. "bench_seat") end
	set(hx1, 0, 2, N .. "plant") set(hx1, 0, 24, N .. "plant")
	for x = 22, 66, 3 do
		local near_door = false
		for _, d in ipairs({27, 37, 46, P.door, P.door + 1}) do if math.abs(x - d) <= 1 then near_door = true end end
		if not near_door then set(x, 0, G.z0, (x % 2 == 0) and N .. "case" or N .. "exhibit") end
	end
	for _, z in ipairs({21, 22}) do set(3, 0, z, N .. "bench_seat") set(4, 0, z, N .. "bench_seat") end
	set(1, 0, 25, N .. "plant")
	fill(P.x0, 0, P.z0, P.x0, 2, P.z1 - 2, N .. "toolwall", 1)
	for _, isl in ipairs({{P.x0 + 3, 3}, {P.x0 + 8, 3}, {P.x0 + 3, 8}, {P.x0 + 8, 8}, {P.x0 + 3, 13}, {P.x0 + 8, 13}}) do
		fill(isl[1], 0, isl[2], isl[1] + 1, 0, isl[2] + 2, N .. "workbench")
		set(isl[1], 1, isl[2] + 1, N .. "printer")
		set(isl[1] - 1, 0, isl[2], N .. "stool") set(isl[1] + 2, 0, isl[2] + 2, N .. "stool")
	end
	-- sustainability: solar roof, rainwater cistern by the courtyard entrance
	for x = 2, 76, 3 do
		for z = 3, 24, 2 do set(x, 16, z, N .. "solar") set(x + 1, 16, z, N .. "solar") end
	end
	fill(86, 0, -4, 88, 2, -2, N .. "cistern")
	infopoint("aceb_atrium") infopoint("aceb_proto") infopoint("aceb_sustain")
end

-- SEB interior from the plans (world coordinates, SEB-02) -------------------------------------------
local function build_seb()
	-- Measured off SEB-02 (wall lines in world metres are in the comments).
	-- EX.7: door on the south side of a passage (z 106.3..108.9) that runs west past stair ST.2,
	-- the landing of ST.3 and elevator EL.A to lobby TA.104, then TA.103 north to TA.101.
	room(-11, 10, 107, 108, N .. "terrazzo")
	for t = 1, 4 do set(11 + t - 1, 5, 107, N .. "sign_seb_" .. t) end
	fill(7, 3, 105, 11, 3, 106, N .. "sandstone_trim")                              -- porch roof over EX.7
	room(-9, -7, 104, 106, N .. "terrazzo")                                          -- TA.104 (x -9.5..-6.7, z 103.4..108)
	door(-4, 106, true) door(0, 106, true)                                           -- stairs ST.3 and ST.2 (upper floors closed)
	door(-5, 109, true) door(-4, 109, true)                                          -- elevator EL.A
	set(-9, 0, 106, N .. "plant")
	room(-11, -10, 109, 113, N .. "terrazzo")                                        -- TA.103 (x -11.8..-9.5, z 109.3..113.6)
	-- main corridor TA.101 (z 113.6..116.1) from the 1959 block (TA.102, closed) to stair ST.1
	room(-30, 21, 114, 115, N .. "terrazzo")
	door(-31, 114, true, true) door(-31, 115, true, true)                            -- TA.102, 1959 block
	for _, x in ipairs({-28, -24, -20, -15, -6, 1, 6, 12, 18}) do door(x, 113, true) end   -- rooms 1060-1085 and beyond
	for _, x in ipairs({-27, -22, -16, -12, -7, 7, 11, 16}) do door(x, 116, true) end      -- rooms 1076, 1077, 1079, 1081
	door(3, 116, true) set(3, 2, 116, N .. "purple")                                -- marker for the Dean's office (actual office: room 2008, second floor; confirmed on site Nov 8)
	-- past ST.1 (x 23..26) into TA.121, the lobby of the lecture-hall extension (z 109.6..114.8)
	room(22, 27, 113, 115, N .. "terrazzo")
	room(28, 49, 110, 114, N .. "terrazzo")
	for _, x in ipairs({31, 37, 43, 48}) do door(x, 109, true) end                   -- rooms 1201-1206
	-- lecture hall 1200 (classroom): double height, tiers rising north away from the front
	local hall = {x0 = 29, x1 = 48, z0 = 116, z1 = 130}   -- walls x 28.6 and 48.5; front wall z 115; z 131 is the north wall
	room(hall.x0, hall.x1, hall.z0, hall.z1, N .. "carpet", 5)         -- ceiling at y 6, roof above
	door(30, 115, false) door(47, 115, false)
	fill(33, 1, 116, 44, 2, 116, N .. "whiteboard")
	set(38, 0, 117, N .. "lectern")
	for i = 0, 12 do                         -- two rows per 0.5 m tier, z 118..130
		local L = math.floor(i / 2) + 1
		local s = -0.5 + 0.5 * L
		local z = 118 + i
		for x = hall.x0, hall.x1 do
			if s % 1 == 0 then
				set(x, s, z, N .. "carpet_slab")
				if s > 0 then fill(x, 0, z, x, s - 1, z, N .. "carpet") end
			else
				fill(x, 0, z, x, s - 0.5, z, N .. "carpet_step")
			end
		end
		if L % 2 == 0 then                   -- desks and seats on the full-height tiers, aisles kept clear
			for x = hall.x0 + 4, hall.x1 - 4 do
				if x ~= 38 then set(x, L / 2, z, (i % 2 == 0) and N .. "desk" or N .. "chair") end
			end
		end
	end
	lights(hall.x0, hall.x1, hall.z0, hall.z1, 5)
	lights(-11, 10, 107, 108, 2) lights(-9, -7, 104, 106, 2) lights(-11, -10, 109, 113, 2) lights(-30, 21, 114, 115, 2)
	lights(22, 27, 113, 115, 2) lights(28, 49, 110, 114, 2)
	infopoint("seb_hall") infopoint("seb_dean") infopoint("seb_classroom")
end

-- interior walls: any dark fill that now faces an open space gets a painted wall finish
local function finish_walls()
	local air, dark, wall = cid("air"), cid(N .. "dark"), cid(N .. "wall")
	for z = -80, 140 do
		for y = -5, 14 do
			for x = -60, 60 do
				local i = area:index(x, y, z)
				if data[i] == dark then
					if data[area:index(x + 1, y, z)] == air or data[area:index(x - 1, y, z)] == air
							or data[area:index(x, y, z + 1)] == air or data[area:index(x, y, z - 1)] == air then
						data[i] = wall
					end
				end
			end
		end
	end
end

-- Main entry point --------------------------------------------------------------------------------
function weve.build_all(on_done)
	minetest.log("action", "[weve] generating campus ...")
	vm = minetest.get_voxel_manip()
	local e1, e2 = vm:read_from_map(REGION_MIN, REGION_MAX)
	area = VoxelArea:new({MinEdge = e1, MaxEdge = e2})
	data, p2 = vm:get_data(), vm:get_param2_data()
	meta_jobs = {}
	TF = nil
	build_site()
	TF = teb
	build_building(teb)
	details_teb(teb)
	TF = aceb
	build_aceb()
	TF = nil
	build_seb()
	finish_walls()
	vm:set_data(data)
	vm:set_param2_data(p2)
	vm:write_to_map(true)
	for _, j in ipairs(meta_jobs) do
		local m = minetest.get_meta(j.pos)
		m:set_string("poi", j.id)
		local p = weve.pois[j.id]
		m:set_string("infotext", "Info point: " .. (p and p.title or j.id) .. " (right-click)")
	end
	vm, area, data, p2 = nil, nil, nil, nil
	if weve.apply_edits then weve.apply_edits() end      -- the team's manual fixes (editor.lua)
	minetest.log("action", "[weve] campus generated: " .. #meta_jobs .. " info points placed")
	if on_done then on_done() end
end

local storage = minetest.get_mod_storage()
local BUILD_VERSION = "13"

function weve.ensure_built(force, on_done)
	if not force and storage:get_string("built") == BUILD_VERSION then
		if on_done then on_done(false) end
		return
	end
	minetest.emerge_area(REGION_MIN, REGION_MAX, function(_, _, remaining)
		if remaining == 0 then
			weve.build_all(function()
				storage:set_string("built", BUILD_VERSION)
				if on_done then on_done(true) end
			end)
		end
	end)
end

-- Keep visitors safe while the campus is generated. In an empty singlenode world a visitor who
-- joins before generation finishes would fall into the void and end up inside the ground
-- (a black screen). Hold them at the hub until the campus exists, then release them.
weve.ready = false
local function release_all()
	for _, pl in ipairs(minetest.get_connected_players()) do
		pl:set_physics_override({speed = 1, jump = 1, gravity = 1})
		pl:set_pos(weve.hub_spawn.pos)
		pl:set_look_horizontal(weve.hub_spawn.yaw)
	end
end
local function campus_ready()
	weve.ready = true
	minetest.set_timeofday(0.5)   -- always midday (time_speed = 0)
	release_all()
	if #minetest.get_connected_players() > 0 then minetest.chat_send_all("Campus ready. Welcome!") end
end
minetest.register_on_joinplayer(function(player)
	if not weve.ready then
		player:set_physics_override({speed = 0, jump = 0, gravity = 0})
		player:set_pos(weve.hub_spawn.pos)
		minetest.chat_send_player(player:get_player_name(), "Building the campus, one moment ...")
	end
end)
-- safety net: anyone below the ground (fell, or spawned inside it) goes back to the hub
local fall_timer = 0
minetest.register_globalstep(function(dtime)
	fall_timer = fall_timer + dtime
	if fall_timer < 1 then return end
	fall_timer = 0
	if not weve.ready then return end
	for _, pl in ipairs(minetest.get_connected_players()) do
		local pos = pl:get_pos()
		if pos.y < -6 or (pos.y < -1.5 and not weve.indoor(pos)) then
			pl:set_pos(weve.hub_spawn.pos)
			pl:set_look_horizontal(weve.hub_spawn.yaw)
		end
	end
end)

minetest.after(0.5, function() weve.ensure_built(false, campus_ready) end)

minetest.register_chatcommand("weve_rebuild", {
	description = "Regenerate the whole WEVE campus from the layout code (operators only)",
	privs = {server = true},
	func = function(name)
		weve.ensure_built(true, function() release_all() minetest.chat_send_player(name, "WEVE campus regenerated.") end)
		return true, "Regenerating the campus ..."
	end,
})
