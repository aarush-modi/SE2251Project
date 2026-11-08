# WEVE staff guide: updating content without a developer (BR-13, FR-07)

All visible text, photos and links live in one file. You never need to edit code or the map.

## Change text or links (about 10 minutes)

1. Open `weve/mods/weve/content/weve_content.json` in any text editor (Notepad, TextEdit, VS Code).
   To keep the original untouched, copy it into the world folder (`worlds/WEVE/weve_content.json`). A copy there takes priority.
2. Find the info point by its `"title"`, then edit `"text"`, `"title"` or the `"links"` list. Keep the quotation marks and commas exactly as they are.
3. Save the file. Restart the game, or type `/weve_reload` as an operator.
4. Right-click the info point in the game to check the change.

If the panel stops showing your text, the file probably has a missing comma or quote. Paste it into any online "JSON validator" to find the line.

## Replace a photo

1. Get approval first: the photo must pass the privacy review (A-13), with no faces, names, screens, documents or whiteboard writing.
2. Save it as a PNG of about 640 x 400 pixels, with exactly the file name given in `"image"` (for example `weve_photo_teb_lab.png`).
3. Replace the file in `weve/mods/weve/textures/`, then restart the game.

## Rebuild the companion web page

Run `python3 tools/build_companion.py weve/mods/weve/content/weve_content.json weve/mods/weve/textures companion` and publish the `companion` folder.

## Fix a wall or door yourself

1. Open the WEVE world in single-player, or on the team server with the `weve_builder` privilege.
2. Type `/weve_builder`. The builder wand appears in slot 2.
3. Point at a block. Left-click removes it. Right-click places the selected block; right-click the air to choose one from the palette. Sneak + left-click copies a block you can see.
4. Made a mistake? Type `/weve_undo`.
5. Your changes are saved automatically and survive a rebuild. To give them to the team, type `/weve_edits_export` and send the file it names to whoever packages the game.
