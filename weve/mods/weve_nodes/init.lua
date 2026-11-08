-- WEVE building blocks. Every node is undiggable: visitors explore, they do not build.
local S = minetest.get_translator and minetest.get_translator("weve_nodes") or function(s) return s end

local function base(def)
	def.groups = def.groups or {}
	def.groups.not_in_creative_inventory = 1
	def.diggable = false
	def.is_ground_content = false
	return def
end

local function cube(name, desc, tiles, extra)
	local def = {description = desc, tiles = tiles}
	for k, v in pairs(extra or {}) do def[k] = v end
	minetest.register_node("weve_nodes:" .. name, base(def))
end

-- ground and paving
cube("grass", "Grass", {"weve_grass.png", "weve_dirt.png", "weve_dirt.png^(weve_grass.png^[resize:16x4)"})
cube("dirt", "Dirt", {"weve_dirt.png"})
cube("path", "Paved path", {"weve_path.png"})
cube("plaza", "Plaza paving", {"weve_plaza.png"})
cube("asphalt", "Asphalt", {"weve_asphalt.png"})
cube("asphalt_line", "Asphalt with line", {"weve_asphalt_line.png"})

-- walls and structure
cube("sandstone", "Sandstone (SEB)", {"weve_sandstone.png"})
cube("sandstone_trim", "Sandstone trim (SEB)", {"weve_sandstone_trim.png"})
cube("brick", "Red brick", {"weve_brick.png"})
cube("limestone", "Pale limestone (TEB)", {"weve_limestone.png"})
cube("concrete", "Light concrete", {"weve_concrete.png"})
cube("concrete_dark", "Dark concrete", {"weve_concrete_dark.png"})
cube("wall", "Painted interior wall", {"weve_wall.png"})
cube("ceiling", "Ceiling", {"weve_ceiling.png"})
cube("purple", "Western purple accent", {"weve_purple.png"})
cube("dark", "Dark finish", {"weve_dark.png"})

-- floors
cube("tile", "Floor tile", {"weve_tile.png"})
cube("terrazzo", "Terrazzo floor", {"weve_terrazzo.png"})
cube("carpet", "Carpet", {"weve_carpet.png"})
cube("wood", "Wood floor", {"weve_wood.png"})

-- glass
for _, g in ipairs({{"glass", "Window glass", "weve_glass.png"}, {"curtain", "Curtain wall glass", "weve_curtain.png"}}) do
	cube(g[1], g[2], {g[3]}, {drawtype = "glasslike", use_texture_alpha = "blend", paramtype = "light", sunlight_propagates = true})
end

-- glass staircase step (ACEB atrium). Lower half plus upper back half, like a standard stair.
-- facedir 0 climbs towards +z.
minetest.register_node("weve_nodes:glass_stair", base({
	description = "Glass stair (ACEB)", tiles = {"weve_glass_stair.png"}, drawtype = "nodebox",
	use_texture_alpha = "blend", paramtype = "light", paramtype2 = "facedir", sunlight_propagates = true,
	node_box = {type = "fixed", fixed = {{-0.5, -0.5, -0.5, 0.5, 0, 0.5}, {-0.5, 0, 0, 0.5, 0.5, 0.5}}},
}))

-- half-height steps: a lower slab and a full block alternate, so stairs climb 0.5 m per block
-- without jumping (glass for the ACEB atrium stairs, carpet for tiered lecture-hall seating).
for _, st in ipairs({{"glass", "weve_glass_stair.png", true}, {"carpet", "weve_carpet.png", false}}) do
	local extra = st[3] and {use_texture_alpha = "blend", sunlight_propagates = true} or {}
	for _, part in ipairs({{"_slab", {-0.5, -0.5, -0.5, 0.5, 0, 0.5}}, {"_step", {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}}}) do
		local def = {description = st[1] .. part[1], tiles = {st[2]}, drawtype = "nodebox", paramtype = "light",
			node_box = {type = "fixed", fixed = part[2]}}
		for k, v in pairs(extra) do def[k] = v end
		minetest.register_node("weve_nodes:" .. st[1] .. part[1], base(def))
	end
end

-- light
minetest.register_node("weve_nodes:light", base({
	description = "Ceiling light", tiles = {"weve_light.png"}, drawtype = "nodebox", paramtype = "light",
	light_source = 13, node_box = {type = "fixed", fixed = {-0.5, 0.375, -0.5, 0.5, 0.5, 0.5}},
	sunlight_propagates = true, walkable = false,
}))

-- invisible barrier for doorway views
minetest.register_node("weve_nodes:barrier", base({
	description = "Invisible barrier", drawtype = "airlike", paramtype = "light", sunlight_propagates = true,
	pointable = false, walkable = true, inventory_image = "weve_blank.png",
}))

-- furniture helpers
local function boxnode(name, desc, tiles, boxes, extra)
	local def = {description = desc, tiles = tiles, drawtype = "nodebox", paramtype = "light", paramtype2 = "facedir",
		node_box = {type = "fixed", fixed = boxes}}
	for k, v in pairs(extra or {}) do def[k] = v end
	minetest.register_node("weve_nodes:" .. name, base(def))
end

boxnode("desk", "Desk", {"weve_wood.png", "weve_dark.png", "weve_dark.png"},
	{{-0.5, 0.3, -0.5, 0.5, 0.4, 0.5}, {-0.45, -0.5, -0.45, -0.35, 0.3, -0.35}, {0.35, -0.5, -0.45, 0.45, 0.3, -0.35},
	 {-0.45, -0.5, 0.35, -0.35, 0.3, 0.45}, {0.35, -0.5, 0.35, 0.45, 0.3, 0.45}})
boxnode("chair", "Chair", {"weve_chair.png"},
	{{-0.3, -0.05, -0.3, 0.3, 0.05, 0.3}, {-0.3, 0.05, 0.25, 0.3, 0.6, 0.3}, {-0.05, -0.5, -0.05, 0.05, -0.05, 0.05}})
boxnode("lab_bench", "Lab bench", {"weve_bench_top.png", "weve_dark.png", "weve_concrete_dark.png"},
	{{-0.5, -0.5, -0.5, 0.5, 0.45, 0.5}})
boxnode("equipment", "Generic lab equipment", {"weve_concrete_dark.png", "weve_concrete_dark.png", "weve_concrete_dark.png",
	"weve_concrete_dark.png", "weve_concrete_dark.png", "weve_equipment.png"}, {{-0.4, -0.5, -0.3, 0.4, 0.1, 0.3}})
boxnode("stool", "Lab stool", {"weve_chair.png"}, {{-0.25, 0.0, -0.25, 0.25, 0.1, 0.25}, {-0.05, -0.5, -0.05, 0.05, 0.0, 0.05}})
boxnode("printer", "3D printer", {"weve_printer.png"}, {{-0.4, -0.5, -0.4, 0.4, 0.4, 0.4}})
boxnode("workbench", "Workbench", {"weve_wood.png", "weve_dark.png", "weve_wood.png"},
	{{-0.5, 0.3, -0.5, 0.5, 0.45, 0.5}, {-0.45, -0.5, -0.45, 0.45, -0.35, 0.45}, {-0.45, -0.35, -0.45, -0.35, 0.3, 0.45}, {0.35, -0.35, -0.45, 0.45, 0.3, 0.45}})
boxnode("bench_seat", "Bench", {"weve_wood.png", "weve_dark.png", "weve_dark.png"},
	{{-0.5, -0.1, -0.3, 0.5, 0.0, 0.3}, {-0.45, -0.5, -0.25, -0.35, -0.1, 0.25}, {0.35, -0.5, -0.25, 0.45, -0.1, 0.25}})
boxnode("lectern", "Lectern", {"weve_wood.png"}, {{-0.3, -0.5, -0.2, 0.3, 0.6, 0.2}})
boxnode("case", "Display case", {"weve_case.png"}, {{-0.45, -0.5, -0.45, 0.45, 0.5, 0.45}},
	{use_texture_alpha = "blend", sunlight_propagates = true})
boxnode("exhibit", "Exhibit", {"weve_exhibit.png"}, {{-0.25, -0.5, -0.25, 0.25, 0.1, 0.25}})
boxnode("plant", "Potted plant", {"weve_leaves.png", "weve_dark.png", "weve_leaves.png"},
	{{-0.2, -0.5, -0.2, 0.2, -0.1, 0.2}, {-0.35, -0.1, -0.35, 0.35, 0.5, 0.35}})
boxnode("ev_charger", "EV charging post", {"weve_concrete_dark.png", "weve_concrete_dark.png", "weve_ev.png"}, {{-0.2, -0.5, -0.2, 0.2, 0.7, 0.2}})
boxnode("solar", "Solar panel", {"weve_solar.png", "weve_concrete_dark.png", "weve_concrete_dark.png"}, {{-0.5, -0.5, -0.5, 0.5, -0.25, 0.5}})

cube("toolwall", "Tool wall", {"weve_toolwall.png"}, {paramtype2 = "facedir"})
cube("whiteboard", "Whiteboard", {"weve_whiteboard.png"}, {paramtype2 = "facedir"})
cube("cistern", "Rainwater cistern", {"weve_cistern.png"})
cube("trunk", "Tree trunk", {"weve_trunk.png"})
cube("leaves", "Leaves", {"weve_leaves.png"}, {drawtype = "allfaces_optional", paramtype = "light"})

-- building name signs: four tiles spell the building code; front face points south (-Z)
for _, code in ipairs({"teb", "seb", "aceb"}) do
	for i = 1, 4 do
		cube("sign_" .. code .. "_" .. i, code:upper() .. " sign " .. i,
			{"weve_purple.png", "weve_purple.png", "weve_purple.png", "weve_purple.png", "weve_purple.png",
			 "weve_sign_" .. code .. "_" .. i .. ".png"}, {paramtype2 = "facedir"})
	end
end
