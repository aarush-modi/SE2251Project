"""Generate the simple 16x16 block textures for the WEVE Luanti game."""
import random, sys, os
from PIL import Image, ImageDraw, ImageFont
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
random.seed(42)
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
def noisy(base, var=10, size=16):
    im = Image.new("RGBA", (size, size))
    px = im.load()
    for x in range(size):
        for y in range(size):
            d = random.randint(-var, var)
            px[x, y] = tuple(max(0, min(255, c + d)) for c in base[:3]) + (base[3] if len(base) > 3 else 255,)
    return im
def save(im, name): im.save(os.path.join(out, name))
def lines(im, color, rows=(), cols=()):
    d = ImageDraw.Draw(im)
    for r in rows: d.line([(0, r), (15, r)], fill=color)
    for c in cols: d.line([(c, 0), (c, 15)], fill=color)
    return im
# ground
save(noisy((92, 150, 70), 14), "weve_grass.png")
save(noisy((120, 90, 60), 12), "weve_dirt.png")
save(noisy((58, 58, 62), 6), "weve_asphalt.png")
save(lines(noisy((58, 58, 62), 6), (230, 230, 230), cols=(15,)), "weve_asphalt_line.png")
save(lines(noisy((178, 178, 172), 6), (140, 140, 135), rows=(7, 15), cols=(7, 15)), "weve_path.png")
save(lines(noisy((150, 138, 170), 6), (110, 95, 135), rows=(7, 15), cols=(7, 15)), "weve_plaza.png")
# building materials
ss = noisy((206, 186, 140), 10); lines(ss, (170, 150, 110), rows=(3, 7, 11, 15)); d = ImageDraw.Draw(ss)
for r, off in ((0, 0), (4, 4), (8, 0), (12, 4)):
    for c in range(off, 16, 8): d.line([(c, r), (c, r + 3)], fill=(170, 150, 110))
save(ss, "weve_sandstone.png")
save(noisy((168, 146, 104), 8), "weve_sandstone_trim.png")
br = noisy((150, 62, 48), 12); lines(br, (200, 190, 180), rows=(3, 7, 11, 15)); d = ImageDraw.Draw(br)
for r, off in ((0, 2), (4, 6), (8, 2), (12, 6)):
    for c in range(off, 16, 8): d.line([(c, r), (c, r + 3)], fill=(200, 190, 180))
save(br, "weve_brick.png")
save(noisy((196, 196, 192), 6), "weve_concrete.png")
save(noisy((120, 122, 126), 6), "weve_concrete_dark.png")
g = Image.new("RGBA", (16, 16), (170, 210, 230, 90)); d = ImageDraw.Draw(g)
d.rectangle([0, 0, 15, 15], outline=(70, 80, 90, 255)); d.line([(3, 12), (12, 3)], fill=(240, 250, 255, 140))
save(g, "weve_glass.png")
cw = Image.new("RGBA", (16, 16), (140, 190, 215, 110)); d = ImageDraw.Draw(cw)
d.rectangle([0, 0, 15, 15], outline=(40, 44, 50, 255)); d.line([(0, 8), (15, 8)], fill=(40, 44, 50, 255))
save(cw, "weve_curtain.png")
save(noisy((228, 226, 220), 4), "weve_wall.png")
save(noisy((240, 240, 236), 3), "weve_ceiling.png")
save(lines(noisy((214, 210, 200), 5), (180, 176, 168), rows=(15,), cols=(15,)), "weve_tile.png")
t = noisy((200, 196, 188), 4)
for _ in range(18): t.putpixel((random.randrange(16), random.randrange(16)), (120, 110, 100, 255))
save(t, "weve_terrazzo.png")
save(noisy((92, 100, 118), 8), "weve_carpet.png")
wd = noisy((170, 125, 80), 10); lines(wd, (140, 100, 60), rows=(4, 9, 14)); save(wd, "weve_wood.png")
save(noisy((70, 72, 76), 5), "weve_dark.png")
p = Image.new("RGBA", (16, 16), (79, 38, 131, 255)); save(p, "weve_purple.png")
# furniture / equipment
save(noisy((60, 60, 64), 4), "weve_bench_top.png")
eq = Image.new("RGBA", (16, 16), (90, 92, 96, 255)); d = ImageDraw.Draw(eq)
d.rectangle([2, 3, 10, 10], fill=(30, 60, 40, 255)); d.line([(3, 8), (5, 5), (7, 8), (9, 5)], fill=(120, 230, 140, 255))
d.ellipse([11, 4, 13, 6], fill=(200, 200, 200, 255)); d.ellipse([11, 8, 13, 10], fill=(200, 200, 200, 255))
save(eq, "weve_equipment.png")
pr = Image.new("RGBA", (16, 16), (225, 225, 228, 255)); d = ImageDraw.Draw(pr)
d.rectangle([1, 1, 14, 14], outline=(60, 60, 60, 255)); d.rectangle([4, 4, 11, 11], fill=(40, 40, 44, 255)); d.rectangle([6, 9, 9, 11], fill=(240, 120, 40, 255))
save(pr, "weve_printer.png")
tw = noisy((180, 150, 105), 6); d = ImageDraw.Draw(tw)
for x in range(2, 16, 4):
    for y in range(2, 16, 4): d.point((x, y), fill=(60, 50, 40, 255))
d.line([(3, 5), (3, 12)], fill=(150, 30, 30, 255)); d.line([(10, 4), (12, 12)], fill=(40, 40, 160, 255))
save(tw, "weve_toolwall.png")
wb = Image.new("RGBA", (16, 16), (246, 246, 246, 255)); ImageDraw.Draw(wb).rectangle([0, 0, 15, 15], outline=(150, 150, 155, 255)); save(wb, "weve_whiteboard.png")
save(noisy((40, 40, 46), 4), "weve_chair.png")
cs = Image.new("RGBA", (16, 16), (200, 230, 240, 70)); d = ImageDraw.Draw(cs); d.rectangle([0, 0, 15, 15], outline=(150, 150, 150, 255)); save(cs, "weve_case.png")
ex = Image.new("RGBA", (16, 16), (79, 38, 131, 255)); d = ImageDraw.Draw(ex); d.rectangle([4, 4, 11, 11], fill=(230, 180, 60, 255)); d.ellipse([6, 6, 9, 9], fill=(255, 240, 200, 255)); save(ex, "weve_exhibit.png")
sp = Image.new("RGBA", (16, 16), (30, 40, 80, 255)); lines(sp, (150, 160, 190, 255), rows=(5, 10, 15), cols=(5, 10, 15)); save(sp, "weve_solar.png")
save(noisy((70, 110, 150), 6), "weve_cistern.png")
ev = Image.new("RGBA", (16, 16), (60, 160, 90, 255)); d = ImageDraw.Draw(ev); d.polygon([(9, 1), (4, 9), (8, 9), (6, 15), (12, 6), (8, 6)], fill=(255, 255, 255, 255)); save(ev, "weve_ev.png")
save(noisy((90, 60, 35), 8), "weve_trunk.png")
lf = noisy((60, 120, 50), 18); save(lf, "weve_leaves.png")
li = Image.new("RGBA", (16, 16), (255, 252, 235, 255)); ImageDraw.Draw(li).rectangle([0, 0, 15, 15], outline=(200, 200, 190, 255)); save(li, "weve_light.png")
# doors
dr = noisy((150, 110, 70), 6); d = ImageDraw.Draw(dr); d.rectangle([0, 0, 15, 15], outline=(90, 65, 40, 255)); d.rectangle([3, 2, 12, 6], fill=(170, 210, 230, 255)); d.point((12, 9), fill=(220, 200, 80, 255)); save(dr, "weve_door.png")
dl = noisy((95, 96, 100), 5); d = ImageDraw.Draw(dl); d.rectangle([0, 0, 15, 15], outline=(60, 60, 64, 255)); d.rectangle([4, 6, 11, 9], fill=(200, 60, 50, 255)); save(dl, "weve_door_locked.png")
# info point and guide
ip = Image.new("RGBA", (16, 16), (79, 38, 131, 255)); d = ImageDraw.Draw(ip); f = ImageFont.truetype(FONT, 13)
d.text((8, 8), "i", font=f, fill=(255, 255, 255, 255), anchor="mm"); save(ip, "weve_infopoint.png")
save(noisy((90, 90, 96), 3), "weve_infopoint_side.png")
gd = Image.new("RGBA", (16, 16), (0, 0, 0, 0)); d = ImageDraw.Draw(gd); d.rectangle([2, 2, 13, 13], fill=(79, 38, 131, 255), outline=(255, 255, 255, 255))
d.line([(5, 10), (8, 5), (11, 10)], fill=(255, 220, 120, 255), width=2); save(gd, "weve_guide.png")
Image.new("RGBA", (16, 16), (0, 0, 0, 0)).save(os.path.join(out, "weve_blank.png"))
# portals and building signs (text split across 4 tiles)
for code, col in (("TEB", (150, 62, 48)), ("SEB", (168, 146, 104)), ("ACEB", (120, 160, 190))):
    pad = Image.new("RGBA", (32, 32), (79, 38, 131, 255)); d = ImageDraw.Draw(pad)
    d.rectangle([1, 1, 30, 30], outline=col + (255,), width=2); d.text((16, 16), code, font=ImageFont.truetype(FONT, 9 if len(code) == 4 else 11), fill=(255, 255, 255, 255), anchor="mm")
    save(pad, f"weve_portal_{code.lower()}.png")
    sign = Image.new("RGBA", (256, 64), (79, 38, 131, 255)); d = ImageDraw.Draw(sign)
    d.text((128, 32), code, font=ImageFont.truetype(FONT, 44), fill=(255, 255, 255, 255), anchor="mm")
    for i in range(4): sign.crop((i * 64, 0, i * 64 + 64, 64)).save(os.path.join(out, f"weve_sign_{code.lower()}_{i + 1}.png"))
# pale limestone with fine joints (TEB)
ls_ = noisy((214, 204, 180), 5); lines(ls_, (190, 180, 156), rows=(7, 15)); save(ls_, "weve_limestone.png")
# glass stair treads (ACEB): pale blue, semi-transparent, white nosing
gs = Image.new("RGBA", (16, 16), (190, 225, 245, 120)); d = ImageDraw.Draw(gs); d.rectangle([0, 0, 15, 15], outline=(245, 250, 255, 230))
save(gs, "weve_glass_stair.png")
# stair marker: up and down arrows on purple
sm = Image.new("RGBA", (16, 16), (79, 38, 131, 255)); d = ImageDraw.Draw(sm)
d.polygon([(4, 7), (8, 2), (12, 7)], fill=(255, 255, 255, 255)); d.polygon([(4, 9), (8, 14), (12, 9)], fill=(255, 220, 120, 255))
save(sm, "weve_stairs.png")
print("textures written to", out)
