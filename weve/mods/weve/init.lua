-- WEVE prototype (Team 50, SE 3351). Entry point.
weve = {
	modpath = minetest.get_modpath("weve"),
	worldpath = minetest.get_worldpath(),
	pois = {},        -- id -> content from weve_content.json, plus pos/look from the builder
	poi_order = {},   -- display order
	tour = {},        -- tour order (ids)
	zones = {},       -- HUD zones filled by the builder
	lobbies = {},     -- building code -> {pos, yaw}
	buildings = {},   -- building code -> {name, short}
}

dofile(weve.modpath .. "/content.lua")
dofile(weve.modpath .. "/nodes.lua")
dofile(weve.modpath .. "/analytics.lua")
dofile(weve.modpath .. "/build.lua")
dofile(weve.modpath .. "/features.lua")
dofile(weve.modpath .. "/editor.lua")
