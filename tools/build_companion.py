"""Build the accessible companion web page (FR-11, NFR-06) from the same content file the game uses.
Usage: python3 build_companion.py <weve_content.json> <photo_dir> <output_dir>"""
import json, sys, os, shutil, html
content, photos, out = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(os.path.join(out, "images"), exist_ok=True)
d = json.load(open(content, encoding="utf-8"))
order = [("hub", "Getting started")] + [(k, f"{v['name']} ({v['short']})") for k, v in d["buildings"].items()]
e = html.escape
parts = []
nav = []
for code, heading in order:
    pois = [p for p in d["pois"] if p["building"] == code]
    if not pois: continue
    nav.append(f'<li><a href="#{code}">{e(heading)}</a></li>')
    items = []
    for p in pois:
        img = p.get("image")
        fig = ""
        if img and os.path.exists(os.path.join(photos, img)):
            try:  # web copy as JPEG keeps the page under the 3 MB budget (NFR-08)
                from PIL import Image
                web = os.path.splitext(img)[0] + ".jpg"
                Image.open(os.path.join(photos, img)).convert("RGB").save(os.path.join(out, "images", web), quality=82, optimize=True)
                img = web
            except ImportError:
                shutil.copy(os.path.join(photos, img), os.path.join(out, "images", img))
            fig = f'<img src="images/{e(img)}" alt="{e(p.get("alt", "Photo of " + p["title"]))}" width="320" height="200">'
        links = "".join(f'<li><a href="{e(l["url"])}">{e(l["label"])}</a></li>' for l in p.get("links", []))
        items.append(f'''<article class="poi" id="{e(p["id"])}">
  <h3>{e(p["title"])}</h3>
  {fig}
  <p>{e(p["text"])}</p>
  {"<h4>Learn more</h4><ul>" + links + "</ul>" if links else ""}
</article>''')
    parts.append(f'<section aria-labelledby="h-{code}"><h2 id="h-{code}">{e(heading)}</h2>\n' + "\n".join(items) + "</section>")
page = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>WEVE Companion Tour</title>
<style>
:root {{ --purple:#4F2683; --ink:#1b1b1f; --paper:#ffffff; --muted:#55505f; --line:#d9d4e3; }}
@media (prefers-color-scheme: dark) {{ :root {{ --ink:#f3f1f7; --paper:#17151c; --muted:#c4bdd3; --line:#3a3446; --purple:#b99be6; }} }}
* {{ box-sizing:border-box; }}
body {{ margin:0; font:1.05rem/1.6 system-ui, -apple-system, "Segoe UI", sans-serif; color:var(--ink); background:var(--paper); }}
a {{ color:var(--purple); }}
a:focus, .skip:focus {{ outline:3px solid #f0b400; outline-offset:2px; }}
.skip {{ position:absolute; left:-999px; top:0; background:#fff; color:#000; padding:.5rem 1rem; }}
.skip:focus {{ left:1rem; }}
header {{ background:#4F2683; color:#fff; padding:1.5rem 1rem; }}
header p {{ margin:.25rem 0 0; }}
main {{ max-width:48rem; margin:0 auto; padding:1rem; }}
nav ul {{ padding-left:1.2rem; }}
section {{ border-top:2px solid var(--line); margin-top:2rem; }}
.poi {{ margin:1.5rem 0; }}
.poi img {{ max-width:100%; height:auto; border:1px solid var(--line); }}
.note {{ color:var(--muted); font-size:.95rem; }}
footer {{ max-width:48rem; margin:2rem auto; padding:0 1rem 2rem; color:var(--muted); font-size:.9rem; }}
</style>
</head>
<body>
<a class="skip" href="#content">Skip to the tour</a>
<header><h1>Western Engineering Virtual Explorer: text tour</h1>
<p>An accessible companion to the WEVE 3D prototype. Every space and point of interest from the 3D tour is described here.</p></header>
<main id="content">
<p class="note">Prototype by SE 3351 Team 50. Draft content, not Western-approved. Photos are placeholders until they pass the privacy review.</p>
<nav aria-label="Buildings"><h2>Contents</h2><ul>{"".join(nav)}</ul></nav>
{"".join(parts)}
</main>
<footer>Generated from weve_content.json, the same file the 3D prototype uses, so both stay in step. Building facts come from public Western University and Western Engineering sources.</footer>
</body>
</html>'''
open(os.path.join(out, "index.html"), "w", encoding="utf-8").write(page)
print("wrote", os.path.join(out, "index.html"))
