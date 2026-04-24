#!/usr/bin/env python3
"""
BeeWealth Icon Processor v3
- Removes white background (makes transparent)
- Finds tight bee bounding box
- Scales bee to fill 92% of icon (leaves 4% each side)
- Adds black background matching the bee's inner dark color
- Regenerates all Android + iOS icon sizes
"""

import struct, zlib, os, subprocess

SRC      = "assets/images/app_icon.png"
OUT_ICON = "assets/images/app_icon_final.png"

# ── PNG decode ────────────────────────────────────────────────────────────────
def read_png(path):
    with open(path, "rb") as f:
        data = f.read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    pos, chunks = 8, {}
    while pos < len(data):
        ln    = struct.unpack('>I', data[pos:pos+4])[0]
        ctype = data[pos+4:pos+8].decode('ascii')
        cdata = data[pos+8:pos+8+ln]
        chunks.setdefault(ctype, []).append(cdata)
        pos += 12 + ln
    ihdr = chunks['IHDR'][0]
    w, h = struct.unpack('>II', ihdr[:8])
    ct   = ihdr[9]
    bpp  = {0:1,2:3,4:2,6:4}[ct]
    raw  = zlib.decompress(b''.join(chunks.get('IDAT',[])))
    stride = w * bpp
    rows, prev, idx = [], bytes(stride), 0
    for _ in range(h):
        ft  = raw[idx]; idx += 1
        row = bytearray(raw[idx:idx+stride]); idx += stride
        if ft == 1:
            for x in range(bpp, stride): row[x] = (row[x]+row[x-bpp])&0xFF
        elif ft == 2:
            for x in range(stride): row[x] = (row[x]+prev[x])&0xFF
        elif ft == 3:
            for x in range(stride):
                a=row[x-bpp] if x>=bpp else 0
                row[x]=(row[x]+(a+prev[x])//2)&0xFF
        elif ft == 4:
            for x in range(stride):
                a=row[x-bpp] if x>=bpp else 0
                b=prev[x]; c=prev[x-bpp] if x>=bpp else 0
                pa=abs(b-c); pb=abs(a-c); pc=abs(a+b-2*c)
                pr=a if pa<=pb and pa<=pc else (b if pb<=pc else c)
                row[x]=(row[x]+pr)&0xFF
        rows.append(bytes(row)); prev=bytes(row)
    return w, h, bpp, ct, rows

def px(rows, bpp, x, y):
    o = x*bpp; r = rows[y]
    if bpp==4: return r[o],r[o+1],r[o+2],r[o+3]
    if bpp==3: return r[o],r[o+1],r[o+2],255
    v=r[o]; return v,v,v,255

# ── PNG encode ─────────────────────────────────────────────────────────────────
def write_png(path, rows, w, h):
    """Always writes RGBA PNG."""
    raw = b''.join(b'\x00'+r for r in rows)
    idat = zlib.compress(raw, 9)
    def chunk(t, d):
        c = t.encode()+d
        return struct.pack('>I',len(d))+c+struct.pack('>I',zlib.crc32(c)&0xFFFFFFFF)
    ihdr = struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)
    with open(path,'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(chunk('IHDR', ihdr))
        f.write(chunk('IDAT', idat))
        f.write(chunk('IEND', b''))

# ── Processing ────────────────────────────────────────────────────────────────
print("🐝 BeeWealth Icon Processor v3")
print("="*42)
print(f"\n📂 Loading {SRC} ...")
W, H, BPP, CT, ROWS = read_png(SRC)
print(f"   {W}×{H}, bpp={BPP}")

# Step 1: Convert every pixel to RGBA, remove white bg
print("\n🎨 Removing white background...")
THRESH = 230   # pixels whiter than this threshold → transparent

rgba = []
for y in range(H):
    row = bytearray()
    for x in range(W):
        r,g,b,a = px(ROWS, BPP, x, y)
        # Flood-fill style: edge-connected white → transparent
        # Simple approach: if pixel is very light AND original alpha is full → transparent
        brightness = (int(r)+g+b)//3
        if a > 200 and r >= THRESH and g >= THRESH and b >= THRESH:
            a = 0   # make transparent
        row += bytes([r,g,b,a])
    rgba.append(bytes(row))

# Step 2: Find tight bounding box of visible (non-transparent) pixels
print("🔍 Finding bee bounding box...")
min_x, min_y, max_x, max_y = W, H, 0, 0
for y in range(H):
    for x in range(W):
        o = x*4
        if rgba[y][o+3] > 40:           # pixel has some opacity
            if x < min_x: min_x = x
            if x > max_x: max_x = x
            if y < min_y: min_y = y
            if y > max_y: max_y = y

bee_w = max_x - min_x + 1
bee_h = max_y - min_y + 1
print(f"   Bee area: ({min_x},{min_y}) → ({max_x},{max_y})  →  {bee_w}×{bee_h}px")

# Step 3: Build 1024×1024 output — black background + scaled bee at 92% fill
OUT_SIZE   = 1024
FILL_PCT   = 0.92          # bee fills 92% of the icon
FILL_PX    = int(OUT_SIZE * FILL_PCT)
OFFSET     = (OUT_SIZE - FILL_PX) // 2   # 4% margin each side

print(f"\n📐 Compositing: bee scaled to {FILL_PX}×{FILL_PX}px, offset={OFFSET}px...")

# Scale bee region → FILL_PX × FILL_PX  (nearest-neighbour)
bee_src_w = bee_w
bee_src_h = bee_h

# Create black-background canvas
BLACK_BG = bytes([0, 0, 0, 255])
canvas = [bytearray(BLACK_BG * OUT_SIZE) for _ in range(OUT_SIZE)]

for dy in range(FILL_PX):
    sy = int(dy * bee_src_h / FILL_PX) + min_y
    sy = min(sy, H-1)
    for dx in range(FILL_PX):
        sx = int(dx * bee_src_w / FILL_PX) + min_x
        sx = min(sx, W-1)
        o_src = sx * 4
        r,g,b,a = rgba[sy][o_src], rgba[sy][o_src+1], rgba[sy][o_src+2], rgba[sy][o_src+3]
        # Alpha-composite over black background
        alpha = a / 255.0
        cr = int(r * alpha)
        cg = int(g * alpha)
        cb = int(b * alpha)
        ca = 255   # fully opaque output (for Android compatibility)
        oy = OFFSET + dy
        ox = OFFSET + dx
        if 0 <= oy < OUT_SIZE and 0 <= ox < OUT_SIZE:
            o_dst = ox * 4
            canvas[oy][o_dst]   = cr
            canvas[oy][o_dst+1] = cg
            canvas[oy][o_dst+2] = cb
            canvas[oy][o_dst+3] = ca

canvas_bytes = [bytes(r) for r in canvas]

print(f"💾 Saving: {OUT_ICON}")
write_png(OUT_ICON, canvas_bytes, OUT_SIZE, OUT_SIZE)
print("   ✅ Final icon saved!")

# Step 4: Generate all sizes with sips
def gen(folder, name, size):
    os.makedirs(folder, exist_ok=True)
    out = os.path.join(folder, name)
    subprocess.run(["sips","-z",str(size),str(size),OUT_ICON,"--out",out], capture_output=True)
    print(f"  ✅ {folder}/{name} → {size}×{size}px")

print("\n📱 Android icons...")
ANDROID = "android/app/src/main/res"
for f,s in [("mipmap-mdpi",48),("mipmap-hdpi",72),("mipmap-xhdpi",96),
             ("mipmap-xxhdpi",144),("mipmap-xxxhdpi",192)]:
    gen(f"{ANDROID}/{f}", "ic_launcher.png", s)
    gen(f"{ANDROID}/{f}", "ic_launcher_round.png", s)

print("\n🍎 iOS icons...")
IOS = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
for name,size in [
    ("Icon-App-20x20@1x",20),("Icon-App-20x20@2x",40),("Icon-App-20x20@3x",60),
    ("Icon-App-29x29@1x",29),("Icon-App-29x29@2x",58),("Icon-App-29x29@3x",87),
    ("Icon-App-40x40@1x",40),("Icon-App-40x40@2x",80),("Icon-App-40x40@3x",120),
    ("Icon-App-60x60@2x",120),("Icon-App-60x60@3x",180),
    ("Icon-App-76x76@1x",76),("Icon-App-76x76@2x",152),
    ("Icon-App-83_5x83_5@2x",167),("Icon-App-1024x1024@1x",1024),
]:
    gen(IOS, f"{name}.png", size)

print("\n"+"="*42)
print("✅ Done! Bee fills 92% of each icon.")
print("   Run: flutter run")
