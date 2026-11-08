"""Placeholder images for info points. Replace each file with a vetted photo (same file name) after the privacy review."""
import sys, os, json
from PIL import Image, ImageDraw, ImageFont
content, out = sys.argv[1], sys.argv[2]; os.makedirs(out, exist_ok=True)
F = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"; FB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
data = json.load(open(content))
for poi in data["pois"]:
    im = Image.new("RGB", (320, 200), (232, 228, 238)); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 319, 199], outline=(79, 38, 131), width=4)
    title = poi["title"]
    size = 16 if len(title) <= 30 else 12
    if len(title) > 40: title = title[:40] + "..."
    d.text((160, 70), title, font=ImageFont.truetype(FB, size), fill=(79, 38, 131), anchor="mm")
    d.text((160, 115), "Photo placeholder", font=ImageFont.truetype(F, 14), fill=(60, 60, 60), anchor="mm")
    d.text((160, 140), "Replace after privacy review (A-13)", font=ImageFont.truetype(F, 12), fill=(90, 90, 90), anchor="mm")
    im.save(os.path.join(out, poi["image"]))
print(len(data["pois"]), "placeholders")
