-- Visitor features: info panels (FR-03/04/09), building selection (FR-01), quick travel and
-- guided tour (FR-06), location HUD (FR-05), visitor restrictions (BR-10/BR-12), intro card.
local E = minetest.formspec_escape
local tour_state = {}   -- player name -> index in weve.tour
local guide_sel = {}    -- player name -> list of ids shown in the guide
local hud = {}          -- player name -> {loc = id, zone = label, building = code}

local function teleport(player, pos, yaw)
	player:set_pos(pos)
	if yaw and player.set_look_horizontal then
		player:set_look_horizontal(yaw)
		player:set_look_vertical(0.15)
	end
end

local function building_label(code)
	local b = weve.buildings[code]
	if code == "hub" then return "Hub" end
	return b and b.short or code
end

-- Info panel ----------------------------------------------------------------------
function weve.show_poi(player, id)
	local p = weve.pois[id]
	if not p then return end
	local name = player:get_player_name()
	local lines = {}
	for _, l in ipairs(p.links) do lines[#lines + 1] = (l.label or "Link") .. ": " .. (l.url or "") end
	local fs = {
		"formspec_version[4]", "size[13,9.4]",
		"box[0,0;13,1;#4F2683]",
		"label[0.4,0.5;", E(building_label(p.building) .. "  |  " .. (p.title or id)), "]",
		"image[0.4,1.4;5.2,3.25;", E(p.image or "weve_blank.png"), "]",
		"textarea[6,1.4;6.6,4.6;;;", E(p.text or ""), "]",
		"textarea[0.4,6.2;12.2,1.5;;Program and recruitment links (select a link and copy it);", E(table.concat(lines, "\n")), "]",
		"label[0.4,8.6;Draft content, not Western-approved.]",
		"button_exit[10.6,8.2;2,0.8;close;Close]",
	}
	if tour_state[name] then
		fs[#fs + 1] = "button[5.9,8.2;2.3,0.8;tour_end;End tour]"
		fs[#fs + 1] = "button[8.3,8.2;2.2,0.8;tour_next;Next stop]"
		fs[#fs + 1] = "label[0.4,4.95;Guided tour: stop " .. tour_state[name] .. " of " .. #weve.tour .. "]"
	end
	minetest.show_formspec(name, "weve:poi", table.concat(fs))
	weve.track(player, "poi_open", id)
end

-- Building selection --------------------------------------------------------------
function weve.go_building(player, code)
	local l = weve.lobbies[code]
	if not l then return false end
	teleport(player, l.pos, l.yaw)
	weve.track(player, "building_select", code)
	return true
end

local function go_hub(player)
	teleport(player, weve.hub_spawn.pos, weve.hub_spawn.yaw)
end

-- Guided tour -----------------------------------------------------------------------
local function tour_goto(player, i)
	local name = player:get_player_name()
	local id = weve.tour[i]
	local p = id and weve.pois[id]
	if not p then
		tour_state[name] = nil
		minetest.chat_send_player(name, "Guided tour complete. Use the guide item or /go to keep exploring.")
		weve.track(player, "tour_complete", "")
		minetest.close_formspec(name, "weve:poi")
		return
	end
	tour_state[name] = i
	if p.pos then teleport(player, p.pos, p.yaw) end
	weve.show_poi(player, id)
end

local function tour_start(player)
	weve.track(player, "tour_start", "")
	tour_goto(player, 1)
end

-- Quick-travel guide --------------------------------------------------------------------
function weve.show_guide(player)
	local name = player:get_player_name()
	local rows, ids = {}, {}
	for _, code in ipairs({"hub", "teb", "seb", "aceb"}) do
		local b = weve.buildings[code]
		rows[#rows + 1] = "#E0C8FF" .. E(code == "hub" and "Hub" or (b and (b.short .. " - " .. b.name) or code))
		ids[#ids + 1] = false
		for _, id in ipairs(weve.poi_order) do
			local p = weve.pois[id]
			if p.building == code then
				rows[#rows + 1] = E("    " .. (p.title or id))
				ids[#ids + 1] = id
			end
		end
	end
	guide_sel[name] = {ids = ids, sel = nil}
	local fs = {
		"formspec_version[4]", "size[12.4,9]",
		"box[0,0;12.4,0.9;#4F2683]", "label[0.4,0.45;WEVE guide: pick a place and press Go]",
		"textlist[0.4,1.2;7.8,7.4;list;", table.concat(rows, ","), ";1;false]",
		"button[8.5,1.2;3.5,0.8;go;Go to selected]",
		"button[8.5,2.2;3.5,0.8;tour;Start guided tour]",
		"label[8.5,3.45;Jump to a building]",
		"button[8.5,3.8;1.1,0.8;b_teb;TEB]", "button[9.7,3.8;1.1,0.8;b_seb;SEB]", "button[10.9,3.8;1.1,0.8;b_aceb;ACEB]",
		"button[8.5,4.9;3.5,0.8;hub;Back to the hub]",
		"button[8.5,5.9;3.5,0.8;help;Controls and help]",
		"button_exit[8.5,7.8;3.5,0.8;close;Close]",
	}
	minetest.show_formspec(name, "weve:guide", table.concat(fs))
end

-- Intro / controls card (helps R-08) ------------------------------------------------------
local function show_intro(player)
	local text = table.concat({
		"Welcome to the Western Engineering Virtual Explorer (prototype).",
		"",
		"Move: W A S D. Look: mouse. Jump: Space.",
		"Info points: purple pedestals. Right-click one to read about the space.",
		"Buildings: right-click a purple pad on the hub (TEB, SEB, ACEB), or type /building teb.",
		"Quick travel and guided tour: click with the guide item in your hand, or type /go.",
		"Your location is shown at the top of the screen.",
		"Grey doors lead to areas that are not part of the tour.",
		"",
		"No account is needed and no personal information is collected.",
	}, "\n")
	minetest.show_formspec(player:get_player_name(), "weve:intro", table.concat({
		"formspec_version[4]", "size[11,7.2]", "box[0,0;11,0.9;#4F2683]", "label[0.4,0.45;How to explore]",
		"textarea[0.4,1.2;10.2,4.9;;;", E(text), "]",
		"button_exit[3.8,6.2;3.4,0.8;start;Start exploring]",
	}))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if formname == "weve:poi" then
		if fields.tour_next and tour_state[name] then tour_goto(player, tour_state[name] + 1)
		elseif fields.tour_end then
			tour_state[name] = nil
			minetest.close_formspec(name, "weve:poi")
		end
		return true
	elseif formname == "weve:guide" then
		local g = guide_sel[name]
		if fields.list and g then
			local ev = minetest.explode_textlist_event(fields.list)
			if ev.type == "CHG" or ev.type == "DCL" then
				g.sel = g.ids[ev.index] or nil
				if ev.type == "DCL" then fields.go = true end
			end
		end
		if fields.go and g and g.sel then
			local p = weve.pois[g.sel]
			tour_state[name] = nil
			minetest.close_formspec(name, "weve:guide")
			if p and p.pos then teleport(player, p.pos, p.yaw) end
			weve.track(player, "quick_travel", g.sel)
		elseif fields.tour then
			minetest.close_formspec(name, "weve:guide")
			tour_start(player)
		elseif fields.b_teb or fields.b_seb or fields.b_aceb then
			minetest.close_formspec(name, "weve:guide")
			weve.go_building(player, fields.b_teb and "teb" or fields.b_seb and "seb" or "aceb")
		elseif fields.hub then
			minetest.close_formspec(name, "weve:guide")
			go_hub(player)
		elseif fields.help then
			show_intro(player)
		end
		return true
	end
end)

-- Location HUD and building-entry analytics ---------------------------------------------
local function zone_at(pos)
	for _, z in ipairs(weve.zones) do
		if pos.x >= z.x0 - 0.5 and pos.x <= z.x1 + 0.5 and pos.z >= z.z0 - 0.5 and pos.z <= z.z1 + 0.5
				and pos.y >= z.y0 and pos.y <= z.y1 and (not z.check or z.check(pos)) then
			return z
		end
	end
	return nil
end

local function hud_add(player, def)
	def.type = def.type or def.hud_elem_type
	def.hud_elem_type = def.hud_elem_type or def.type
	return player:hud_add(def)
end

local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 0.5 then return end
	timer = 0
	for _, player in ipairs(minetest.get_connected_players()) do
		local h = hud[player:get_player_name()]
		if h then
			local z = zone_at(player:get_pos())
			local label = z and z.label or "Western Engineering campus (approximate layout)"
			if label ~= h.zone then
				player:hud_change(h.loc, "text", label)
				h.zone = label
			end
			local b = z and z.building or nil
			if b and b ~= h.building and (b == "teb" or b == "seb" or b == "aceb") then
				weve.track(player, "building_enter", b)
			end
			h.building = b
		end
	end
end)

-- Joining: visitor privileges, inventory, HUD, spawn -------------------------------------
local function setup_player(player)
	local name = player:get_player_name()
	if not minetest.is_singleplayer() and not minetest.check_player_privs(name, {server = true})
			and not minetest.check_player_privs(name, {weve_builder = true}) then
		minetest.set_player_privs(name, {interact = true, shout = true}) -- no fly, noclip, teleport or building
	end
	local inv = player:get_inventory()
	inv:set_list("main", {})
	inv:set_list("craft", {})
	inv:add_item("main", "weve:guide")
	if player.hud_set_hotbar_itemcount then player:hud_set_hotbar_itemcount(1) end
	player:hud_set_flags({wielditem = false})
	hud[name] = {zone = ""}
	hud[name].loc = hud_add(player, {hud_elem_type = "text", position = {x = 0.5, y = 0.03}, alignment = {x = 0, y = 1},
		offset = {x = 0, y = 0}, text = "", number = 0xFFFFFF, scale = {x = 100, y = 100}})
	hud_add(player, {hud_elem_type = "text", position = {x = 0.01, y = 0.97}, alignment = {x = 1, y = -1},
		offset = {x = 0, y = 0}, number = 0xE0D0F8, scale = {x = 100, y = 100},
		text = "Right-click purple info points  |  Guide item or /go: quick travel and tour  |  /building teb, seb, aceb"})
	for _, code in ipairs({"teb", "seb", "aceb"}) do
		local l = weve.lobbies[code]
		hud_add(player, {hud_elem_type = "waypoint", name = building_label(code) .. " entrance", text = "m", number = 0xD8C8F0,
			world_pos = {x = l.pos.x, y = 2, z = l.pos.z}})
	end
end

minetest.register_on_joinplayer(function(player)
	setup_player(player)
	local meta = player:get_meta()
	if meta:get_string("weve_intro") ~= "1" then
		meta:set_string("weve_intro", "1")
		minetest.after(1, function()
			if player:is_player() then show_intro(player) end
		end)
	end
end)
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	hud[name], tour_state[name], guide_sel[name] = nil, nil, nil
end)
minetest.register_on_newplayer(function(player) go_hub(player) end)
minetest.register_on_respawnplayer(function(player) go_hub(player) return true end)

-- Fixed daylight
minetest.after(0, function()
	minetest.settings:set("time_speed", "0")
	minetest.set_timeofday(0.5)
end)

-- Chat commands ------------------------------------------------------------------------
minetest.register_chatcommand("building", {
	params = "<teb|seb|aceb|hub>",
	description = "Go to a building entrance (or back to the hub)",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
		local code = param:lower():gsub("%s", "")
		if code == "hub" then go_hub(player) return true, "Back at the hub." end
		if weve.go_building(player, code) then return true, "Welcome to " .. (weve.buildings[code] and weve.buildings[code].name or code) .. "." end
		return false, "Choose teb, seb, aceb or hub."
	end,
})
minetest.register_chatcommand("go", {
	description = "Open the WEVE quick-travel guide",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then weve.show_guide(player) end
		return true
	end,
})
minetest.register_chatcommand("tour", {
	description = "Start the guided tour",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then tour_start(player) end
		return true
	end,
})
minetest.register_chatcommand("weve_help", {
	description = "Show the WEVE controls card",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then show_intro(player) end
		return true
	end,
})
minetest.register_chatcommand("weve_reload", {
	description = "Reload weve_content.json without restarting (operators only)",
	privs = {server = true},
	func = function()
		weve.load_content()
		weve.apply_poi_positions()
		return true, "Content reloaded: " .. #weve.poi_order .. " points of interest."
	end,
})
