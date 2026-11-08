-- Builder mode: lets the team fix details inside the game without touching code.
--
--   /weve_builder        get the builder wand (needs the weve_builder privilege; single-player has it)
--   wand, left-click     remove the block you point at
--   wand, right-click    place the selected block against the face you point at
--   wand, sneak + left   pick the block you point at as the selected block
--   wand, right-click in the air, or /weve_palette   choose a block from the palette
--   /weve_undo           undo your last change (repeatable)
--   /weve_edits          how many edits are saved;  /weve_edits_export  write them out for the team
--
-- Every change is saved in the world folder (weve_edits.json) and re-applied after each rebuild, so
-- edits survive /weve_rebuild and updates to the generator. To ship edits with the game for
-- everyone, copy the exported file to weve/mods/weve/edits/weve_edits.json.
minetest.register_privilege("weve_builder", {
	description = "Can edit the WEVE campus with the builder wand",
	give_to_singleplayer = true, give_to_admin = true,
})

local WORLD_FILE = weve.worldpath .. "/weve_edits.json"
local MOD_FILE = weve.modpath .. "/edits/weve_edits.json"
local function read_json(path)
	local f = io.open(path, "r")
	if not f then return {} end
	local data = minetest.parse_json(f:read("*a")) or {}
	f:close()
	return type(data) == "table" and data or {}
end
local shipped = read_json(MOD_FILE)       -- edits that come with the game
weve.edits = read_json(WORLD_FILE)        -- edits made in this world
local function save()
	minetest.safe_file_write(WORLD_FILE, minetest.write_json(weve.edits))
end
local function key(p) return p.x .. "," .. p.y .. "," .. p.z end
local function unkey(k)
	local x, y, z = k:match("^(-?%d+),(-?%d+),(-?%d+)$")
	return {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
end
function weve.apply_edits()
	local n = 0
	for _, list in ipairs({shipped, weve.edits}) do
		for k, v in pairs(list) do
			local pos = unkey(k)
			if pos and type(v) == "table" and minetest.registered_nodes[v[1]] then
				minetest.set_node(pos, {name = v[1], param2 = v[2] or 0})
				n = n + 1
			end
		end
	end
	if n > 0 then minetest.log("action", "[weve] re-applied " .. n .. " manual edits") end
end

local undo = {}
local function change(player, pos, node)
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then return end
	local k = key(pos)
	undo[name] = undo[name] or {}
	table.insert(undo[name], {pos = pos, old = minetest.get_node(pos), had = weve.edits[k]})
	if #undo[name] > 100 then table.remove(undo[name], 1) end
	minetest.set_node(pos, node)
	weve.edits[k] = {node.name, node.param2 or 0}
	save()
end

local function selected(player)
	local m = player:get_meta()
	local n = m:get_string("weve_builder_node")
	return n ~= "" and n or "weve_nodes:wall"
end
local function palette(player)
	local names = {}
	for n in pairs(minetest.registered_nodes) do
		if (n:sub(1, 11) == "weve_nodes:" or n:sub(1, 5) == "weve:") and not n:find("_open") and not n:find("_top") then
			names[#names + 1] = n
		end
	end
	table.sort(names)
	local fs = {"formspec_version[4]size[13.2,10.2]label[0.4,0.5;Choose a block (selected: " ..
		minetest.formspec_escape(selected(player)) .. ")]"}
	for i, n in ipairs(names) do
		local c, r = (i - 1) % 12, math.floor((i - 1) / 12)
		if r < 8 then
			fs[#fs + 1] = ("item_image_button[%.2f,%.2f;1,1;%s;pick_%s;]tooltip[pick_%s;%s]"):format(
				0.4 + c * 1.05, 1 + r * 1.1, n, n, n, minetest.formspec_escape(minetest.registered_nodes[n].description or n))
		end
	end
	minetest.show_formspec(player:get_player_name(), "weve:palette", table.concat(fs))
end
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "weve:palette" then return end
	for f in pairs(fields) do
		if f:sub(1, 5) == "pick_" then
			player:get_meta():set_string("weve_builder_node", f:sub(6))
			minetest.chat_send_player(player:get_player_name(), "Selected " .. f:sub(6))
			minetest.close_formspec(player:get_player_name(), "weve:palette")
		end
	end
	return true
end)

local function allowed(player)
	return player and player:is_player() and minetest.check_player_privs(player, {weve_builder = true})
end
minetest.register_craftitem("weve:builder_wand", {
	description = "WEVE builder wand\nLeft-click: remove. Right-click: place. Sneak + left-click: pick. Right-click air: palette.",
	inventory_image = "weve_guide.png^[colorize:#e0a000:120",
	stack_max = 1, range = 12,
	groups = {not_in_creative_inventory = 1},
	on_use = function(itemstack, player, pointed)
		if not allowed(player) or pointed.type ~= "node" then return end
		local pos = pointed.under
		if player:get_player_control().sneak then
			local n = minetest.get_node(pos).name
			player:get_meta():set_string("weve_builder_node", n)
			minetest.chat_send_player(player:get_player_name(), "Selected " .. n)
		else
			change(player, pos, {name = "air"})
		end
	end,
	on_place = function(itemstack, player, pointed)
		if not allowed(player) or pointed.type ~= "node" then return end
		local n = selected(player)
		local p2 = 0
		local def = minetest.registered_nodes[n]
		if def and def.paramtype2 == "facedir" then p2 = minetest.dir_to_facedir(player:get_look_dir()) end
		change(player, pointed.above, {name = n, param2 = p2})
		if n == "weve:door" then change(player, vector.add(pointed.above, {x = 0, y = 1, z = 0}), {name = "weve:door_top", param2 = p2})
		elseif n == "weve:door_locked" then change(player, vector.add(pointed.above, {x = 0, y = 1, z = 0}), {name = "weve:door_locked_top", param2 = p2}) end
	end,
	on_secondary_use = function(itemstack, player)
		if allowed(player) then palette(player) end
	end,
})

minetest.register_chatcommand("weve_builder", {
	description = "Get the builder wand to edit the campus",
	privs = {weve_builder = true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
		local inv = player:get_inventory()
		if not inv:contains_item("main", "weve:builder_wand") then inv:add_item("main", "weve:builder_wand") end
		if player.hud_set_hotbar_itemcount then player:hud_set_hotbar_itemcount(2) end
		player:hud_set_flags({wielditem = true})
		return true, "Builder wand added (slot 2; scroll or press 2). Left-click removes, right-click places, " ..
			"sneak + left-click picks a block, right-click the air for the palette. Press K to fly and H to pass through walls " ..
			"(needs the fly and noclip privileges). Edits are saved and survive /weve_rebuild."
	end,
})
minetest.register_chatcommand("weve_palette", {
	description = "Choose the block the builder wand places", privs = {weve_builder = true},
	func = function(name) local p = minetest.get_player_by_name(name) if p then palette(p) end return true end,
})
minetest.register_chatcommand("weve_undo", {
	description = "Undo your last builder edit", privs = {weve_builder = true},
	func = function(name)
		local u = undo[name] and table.remove(undo[name])
		if not u then return false, "Nothing to undo." end
		minetest.set_node(u.pos, u.old)
		weve.edits[key(u.pos)] = u.had
		save()
		return true, "Undone."
	end,
})
minetest.register_chatcommand("weve_edits", {
	description = "Show how many manual edits are saved", privs = {weve_builder = true},
	func = function()
		local n = 0 for _ in pairs(weve.edits) do n = n + 1 end
		return true, n .. " edits saved in this world (weve_edits.json in the world folder)."
	end,
})
minetest.register_chatcommand("weve_edits_export", {
	description = "Write all edits (shipped + this world) to the world folder for the team to commit",
	privs = {weve_builder = true},
	func = function()
		local all = {}
		for _, list in ipairs({shipped, weve.edits}) do for k, v in pairs(list) do all[k] = v end end
		local path = weve.worldpath .. "/weve_edits_export.json"
		minetest.safe_file_write(path, minetest.write_json(all))
		return true, "Saved to " .. path .. ". Copy it to weve/mods/weve/edits/weve_edits.json to ship it with the game."
	end,
})
