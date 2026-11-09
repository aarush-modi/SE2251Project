# WEVE: Western Engineering Virtual Explorer (Luanti prototype)

SE 3351 Group Project, Team 50. A block-based digital twin of three Western Engineering buildings: the Thompson Engineering Building (TEB), the Spencer Engineering Building (SEB) and the Amit Chakma Engineering Building (ACEB). 1 block = 1 metre.

## What is in this package

| Folder | Contents |
| --- | --- |
| `weve/` | The Luanti game. Copy this folder into Luanti's `games` folder. |
| `companion/` | Accessible text version of the tour (`index.html`). Open it in any web browser. |
| `tools/` | Scripts that regenerate textures, photo placeholders and the companion page. |
| `STAFF_GUIDE.md` | How a non-developer updates text, links and photos. |

## Run it (about 5 minutes)

1. Install Luanti (free) from https://www.luanti.org/downloads/. Tested with the Minetest 5.6.1 engine, the release before the rename to Luanti; any Luanti 5.x release should work.
2. Start Luanti, open **About**, click **Open User Data Directory**, then open the `games` folder inside it. Copy the whole `weve` folder there.
3. Restart Luanti. In **Start Game**, click the WEVE icon along the bottom of the window, click **New**, name the world `WEVE` and click **Create**. The only map generator offered is `singlenode`, which is correct.
4. Select the world and press **Play Game**. On the first start the campus takes 2 to 5 seconds to generate.

No other games or mods are needed. No account is needed to explore.

### Let others visit (remote access, NFR-01)

No server is running yet; someone on the team has to host one. There are two ways:

1. **From a team laptop (free, good for the demo).** In Luanti, open **Start Game**, select the WEVE world, tick **Host Server**, enter a name and password for yourself, and press **Host Game**. Keep the laptop awake. Others on the same network open **Join Game** and enter the laptop's IP address (on Windows, `ipconfig`; on macOS, System Settings > Network) and port `30000`. Campus Wi-Fi may block connections between devices; a phone hotspot works for a demo. To reach it from home, the laptop's router must forward UDP port 30000.
2. **On a small cloud machine (always on, about CAD 5-10 a month).** Install the Luanti server (`sudo apt install minetest-server` on Ubuntu), copy the `weve` folder to `~/.minetest/games/`, open UDP port 30000 in the firewall, and run `minetestserver --gameid weve --worldname WEVE --port 30000`. Visitors join with the machine's public address.

Visitors get only the `interact` and `shout` privileges, so they cannot fly, pass through walls, dig or build. Give team members the editing privilege with `/grant <name> weve_builder` (plus `fly` and `noclip` if they need them); the host has every privilege automatically.

**Privacy of the server log (NFR-04, D-21).** WEVE's own analytics never record names or IP addresses, but Luanti's server log (`debug.txt` in the Luanti user folder) records each player's name and IP address when they join. Before a session with visitors, add the line `debug_log_level = warning` to the host's `minetest.conf`, which stops join messages from being written to the log. After a demo, delete `debug.txt`. Never commit or share it.

## How to explore

- Move with W A S D, look with the mouse, jump with Space.
- **Info points** are purple pedestals. Right-click one to open its panel with text, a photo and program links.
- **Choose a building:** right-click a purple pad on the hub plaza, or type `/building teb`, `/building seb` or `/building aceb`. `/building hub` returns to the start.
- **Quick travel and guided tour:** left-click while holding the guide item (the only item in your hotbar), or type `/go`. The tour (`/tour`) visits all 10 info points in order with a **Next stop** button.
- The top of the screen always shows where you are, for example `TEB - Ground floor - Main lobby`.
- In ACEB you can walk up the glass stairs: ST.B from the south entrance to floor 2, the floor 2 corridor to the north atrium, the U-shaped stair ST.E to floor 3 and ST.F to the floor 4 landing.

## Scope implemented

| Building | Included |
| --- | --- |
| TEB | Pale limestone exterior with a glass entrance section, canopy and sign; main lobby; ground-floor main corridor; showcase room: ECE undergraduate teaching lab, seen from the doorway; 3 info points |
| SEB | Sandstone Gothic Collegiate exterior with crenellated parapets and the tower over room 1076; entrance EX.7 from the SEB courtyard; entrance hall; main corridor TA.101; Dean's office door (closed, room still to confirm); showcase room: tiered lecture hall 1200 in the lecture-hall extension; 3 info points |
| ACEB | Curtain-wall exterior with floors 3 and 4 cantilevered over the south end; south entrance EX.23 with a glass vestibule, opening into a double-height space with the open glass stair ST.B up to floor 2 (about 15 m, or 4 seconds' walk, from the doors); floor 2 corridor TA.241 to the north atrium; north atrium hall TA.144 running the full width of the building, with doors to the courtyard (EX.18) and to Western Road (EX.24); U-shaped glass stair ST.E over the atrium to floor 3; ST.F beside it to floor 4, whose north wall lines up with ST.F so floor 4 never covers the atrium; skylight roof; Engineering Galleries along corridor TA.141 with display cases; showcase room: prototyping space in room 1440 (about 250 m2, the 2,500 sq ft space; room still to confirm); solar roof, rainwater cistern and EV chargers; 3 info points |
| Hub | Spawn plaza in the courtyard between ACEB and TEB, three building pads, welcome info point |
| All connected buildings | Exterior of every level from the plans (SEB complex, CMLP, ACEB, the bridge to TEB), including roofs, the SEB tower and the courtyards. Inside, only the approved areas above are open; everything else is closed behind walls and grey doors (FR-02, Doc 6) |

### Where the layout comes from

The SEB complex, the Claudette MacKay-Lassonde Pavilion (CMLP) and ACEB follow the Western Facilities Management floor plans SEB-01 to SEB-05 (2024), drawn at 1/16" = 1'-0". **The plans are available only to Western students and staff (Western login required) and are not included in this package or repository.** The team keeps them, and the scripts that traced them, privately (risk R-17).

- Plan Level 02 (rooms 1xxx) is the floor you walk in on, so it is the ground floor in the game. Levels 03 to 05 are floors 2 to 4. Level 01 is a lower level and is not modelled.
- `weve/mods/weve/site_data.lua` holds **outlines only**: for each level, which 1 m cells are outside, inside the building, or exterior wall. The game builds the facade, floors and roof of every level from it. Interior rooms, walls, exits, stairs and the basement were removed before release.
- **Interiors follow the Task 1 scope.** The plan commits to each building's exterior, its main ground-floor entrance area and one showcase room (Section 4), with approved interiors within 1 m (NFR-09). Other rooms, upper floors, the basement and the Pavilion are excluded (Doc 6). Those parts are closed: solid behind the walls, with grey doors where rooms open off the tour corridors (FR-02).
- **The approved spaces are built by hand** in `build.lua`, with room numbers in the comments: the ACEB south entrance, ST.B, the Engineering Galleries, prototyping space 1440, the north atrium and its stairs; the SEB entrance EX.7, TA.104, TA.103, main corridor TA.101, the TA.121 lobby and lecture hall 1200.
- **TEB** is not in the plan set. Only its north end and the bridge (corridor TA.235 on Level 03) are drawn. That fixes TEB's position and its 23 m width, but its 100 m length is still an estimate from the satellite view.

| Building | Footprint (from the plans) | Storeys |
| --- | --- | --- |
| ACEB | 89 x 27 m | 4 (3 over the atrium) |
| SEB, 1959 block on Western Road | 18 x 44 m | 3 |
| SEB lecture-hall extension (1200, 2200, 2202) | 24 x 35 m | 2 |
| SEB tower over room 1076 | 9 x 10 m | about 6 (roof plan) |
| CMLP | 31 x 39 m | 3 |
| TEB | 23 x 100 m (length estimated) | 4 |

## Edit the campus by hand

**In the game (no code).** Type `/weve_builder` to get the builder wand. You need the `weve_builder` privilege; single-player has it.

- Left-click removes the block you point at, and right-click places the selected block.
- Sneak + left-click copies the block you point at, and right-clicking the air opens the block palette.
- `/weve_undo` undoes your last change.
- Press K to fly and H to pass through walls (needs `fly` and `noclip`).

Every edit is saved in the world folder (`weve_edits.json`) and re-applied after each `/weve_rebuild`. To share your edits with the team, type `/weve_edits_export` and copy the file it writes to `weve/mods/weve/edits/weve_edits.json`. Everyone who installs that version then gets the same fixes.

**In the files.** Building positions and sizes are in `weve/mods/weve/build.lua`: the `BUILDINGS` table, `AC` for ACEB and `build_seb` for SEB. Each room is one line, such as `room(x0, x1, z0, z1, floor)` in world metres. Press F5 in the game to read coordinates. Edit, save, then type `/weve_rebuild`. The outlines come from `tools/levels.py`, and the steps are at the top of each script.

## Commands

| Command | Who | What |
| --- | --- | --- |
| `/go`, `/tour`, `/building <teb, seb, aceb or hub>`, `/weve_help` | Everyone | Navigation and help |
| `/weve_stats` | Operators | Anonymous usage counts from the analytics log |
| `/weve_reload` | Operators | Reload `weve_content.json` without a restart |
| `/weve_rebuild` | Operators | Regenerate the campus from the layout code (manual edits are kept) |
| `/weve_builder`, `/weve_palette`, `/weve_undo`, `/weve_edits`, `/weve_edits_export` | Builders (`weve_builder`) | Edit blocks in the game and share the edits |

## Analytics and privacy (BR-14, NFR-04)

Events are appended to `weve_analytics.csv` in the world folder: UTC time, a random session token, the event (`session_start`, `building_enter`, `building_select`, `poi_open`, `quick_travel`, `tour_start`, `tour_complete`, `restricted_door`, `session_end`) and its target. Player names and IP addresses are never written, and the token is discarded at logout.

## Version control note (risk R-12)

Never commit the world folder (`map.sqlite`): it is binary and cannot be merged. Everything that defines the campus is code (`build.lua`) and content (`weve_content.json`), so the world can always be regenerated.

## AI use disclosure

The game code, textures, photo placeholders, initial info-point text and this README were generated with Claude (Anthropic) on Nov 6, 2026, at Team 50's request, from the team's Task 1 plan. Claude test-ran the game on a Minetest 5.6.1 server and client. Team 50 reviewed and tested it: *(team to record who reviewed, when, and what was changed)*.
