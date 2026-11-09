-- Interactive nodes: doors, restricted doors, info points, hub portal pads, guide item.
local function nodef(def)
	def.groups = {not_in_creative_inventory = 1}
	def.diggable = false
	def.is_ground_content = false
	return def
end

-- Doors (two nodes high). Approved areas use doors that open; restricted areas use locked doors (BR-12).
local closed_box = {-0.5, -0.5, -0.06, 0.5, 0.5, 0.06}
local open_box = {-0.5, -0.5, -0.5, -0.38, 0.5, 0.5}
local pairs_ = {
	["weve:door"] = "weve:door_open", ["weve:door_open"] = "weve:door",
	["weve:door_top"] = "weve:door_top_open", ["weve:door_top_open"] = "weve:door_top",
}
local function toggle(pos)
	for _, dy in ipairs({0, 1, -1}) do
		local p = {x = pos.x, y = pos.y + dy, z = pos.z}
		local n = minetest.get_node(p)
		if pairs_[n.name] then minetest.swap_node(p, {name = pairs_[n.name], param2 = n.param2}) end
	end
end
for _, d in ipairs({
	{"door", closed_box, "weve_door.png"}, {"door_open", open_box, "weve_door.png"},
	{"door_top", closed_box, "weve_door.png^[transformFY"}, {"door_top_open", open_box, "weve_door.png^[transformFY"},
}) do
	minetest.register_node("weve:" .. d[1], nodef({
		description = "Door", tiles = {d[3]}, drawtype = "nodebox", paramtype = "light", paramtype2 = "facedir",
		node_box = {type = "fixed", fixed = d[2]}, sunlight_propagates = true,
		on_rightclick = function(pos) toggle(pos) end,
	}))
end

minetest.register_node("weve:door_locked", nodef({
	description = "Restricted door", tiles = {"weve_door_locked.png"}, drawtype = "nodebox", paramtype = "light",
	paramtype2 = "facedir", node_box = {type = "fixed", fixed = closed_box},
	on_rightclick = function(pos, node, clicker)
		if clicker then
			minetest.chat_send_player(clicker:get_player_name(),
				"This area is not part of the virtual tour.")
			weve.track(clicker, "restricted_door", minetest.pos_to_string(pos))
		end
	end,
}))
minetest.register_node("weve:door_locked_top", nodef({
	description = "Restricted door", tiles = {"weve_door_locked.png^[transformFY"}, drawtype = "nodebox",
	paramtype = "light", paramtype2 = "facedir", node_box = {type = "fixed", fixed = closed_box},
}))

-- Info points (FR-03). The point id is stored in node metadata by the builder.
minetest.register_node("weve:infopoint", nodef({
	description = "Info point", drawtype = "nodebox", paramtype = "light", light_source = 6,
	tiles = {"weve_infopoint.png", "weve_infopoint_side.png", "weve_infopoint_side.png", "weve_infopoint_side.png",
		"weve_infopoint_side.png", "weve_infopoint.png"},
	node_box = {type = "fixed", fixed = {{-0.15, -0.5, -0.15, 0.15, 0.3, 0.15}, {-0.35, 0.3, -0.35, 0.35, 0.5, 0.35}}},
	on_rightclick = function(pos, node, clicker)
		local id = minetest.get_meta(pos):get_string("poi")
		if clicker and id ~= "" then weve.show_poi(clicker, id) end
	end,
	on_punch = function(pos, node, puncher)
		local id = minetest.get_meta(pos):get_string("poi")
		if puncher and id ~= "" then weve.show_poi(puncher, id) end
	end,
}))

-- Hub portal pads (FR-01)
for _, code in ipairs({"teb", "seb", "aceb"}) do
	local function go(pos, node, player) if player then weve.go_building(player, code) end end
	minetest.register_node("weve:portal_" .. code, nodef({
		description = code:upper() .. " entrance pad", drawtype = "nodebox", paramtype = "light", light_source = 8,
		tiles = {"weve_portal_" .. code .. ".png", "weve_purple.png", "weve_purple.png"},
		node_box = {type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5}},
		on_rightclick = go, on_punch = go,
	}))
end

-- Guide item: opens the quick-travel menu (FR-06)
-- The guide is always in hand, so a click on a block with its own action (info point, door, pad,
-- stairs) is passed to that block; any other click opens the guide.
local function guide_click(itemstack, user, pointed, callback)
	if not user then return itemstack end
	if pointed and pointed.type == "node" then
		local node = minetest.get_node(pointed.under)
		local def = minetest.registered_nodes[node.name]
		if def and callback == "on_rightclick" and def.on_rightclick then
			def.on_rightclick(pointed.under, node, user, itemstack, pointed)
			return itemstack
		elseif def and callback == "on_punch" and def.on_punch and def.on_punch ~= minetest.node_punch then
			def.on_punch(pointed.under, node, user, pointed)
			return itemstack
		end
	end
	weve.show_guide(user)
	return itemstack
end
minetest.register_craftitem("weve:guide", {
	description = "WEVE guide (click to open quick travel)",
	inventory_image = "weve_guide.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed) return guide_click(itemstack, user, pointed, "on_punch") end,
	on_secondary_use = function(itemstack, user) if user then weve.show_guide(user) end return itemstack end,
	on_place = function(itemstack, user, pointed) return guide_click(itemstack, user, pointed, "on_rightclick") end,
	on_drop = function(itemstack) return itemstack end,
})
