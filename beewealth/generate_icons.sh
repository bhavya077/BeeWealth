#!/bin/bash
# BeeWealth - Generate Launcher Icons using macOS sips
SRC="assets/images/app_icon.png"

echo "🐝 BeeWealth Icon Generator"
echo "================================"

# ── ANDROID ──────────────────────────────────────────────────────────────────
echo ""
echo "📱 Generating Android icons..."
ANDROID_BASE="android/app/src/main/res"

gen_android() {
  FOLDER=$1; SIZE=$2
  mkdir -p "$ANDROID_BASE/$FOLDER"
  sips -z $SIZE $SIZE "$SRC" --out "$ANDROID_BASE/$FOLDER/ic_launcher.png" > /dev/null 2>&1
  sips -z $SIZE $SIZE "$SRC" --out "$ANDROID_BASE/$FOLDER/ic_launcher_round.png" > /dev/null 2>&1
  echo "  ✅ $FOLDER → ${SIZE}x${SIZE}px"
}

gen_android "mipmap-mdpi"    48
gen_android "mipmap-hdpi"    72
gen_android "mipmap-xhdpi"   96
gen_android "mipmap-xxhdpi"  144
gen_android "mipmap-xxxhdpi" 192

# ── iOS ───────────────────────────────────────────────────────────────────────
echo ""
echo "🍎 Generating iOS icons..."
IOS_BASE="ios/Runner/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$IOS_BASE"

gen_ios() {
  NAME=$1; SIZE=$2
  sips -z $SIZE $SIZE "$SRC" --out "$IOS_BASE/$NAME.png" > /dev/null 2>&1
  echo "  ✅ $NAME → ${SIZE}x${SIZE}px"
}

gen_ios "Icon-App-20x20@1x"      20
gen_ios "Icon-App-20x20@2x"      40
gen_ios "Icon-App-20x20@3x"      60
gen_ios "Icon-App-29x29@1x"      29
gen_ios "Icon-App-29x29@2x"      58
gen_ios "Icon-App-29x29@3x"      87
gen_ios "Icon-App-40x40@1x"      40
gen_ios "Icon-App-40x40@2x"      80
gen_ios "Icon-App-40x40@3x"      120
gen_ios "Icon-App-60x60@2x"      120
gen_ios "Icon-App-60x60@3x"      180
gen_ios "Icon-App-76x76@1x"      76
gen_ios "Icon-App-76x76@2x"      152
gen_ios "Icon-App-83_5x83_5@2x"  167
gen_ios "Icon-App-1024x1024@1x"  1024

# Write Contents.json for iOS
cat > "$IOS_BASE/Contents.json" << 'EOF'
{
  "images" : [
    {"size":"20x20","idiom":"iphone","filename":"Icon-App-20x20@2x.png","scale":"2x"},
    {"size":"20x20","idiom":"iphone","filename":"Icon-App-20x20@3x.png","scale":"3x"},
    {"size":"29x29","idiom":"iphone","filename":"Icon-App-29x29@1x.png","scale":"1x"},
    {"size":"29x29","idiom":"iphone","filename":"Icon-App-29x29@2x.png","scale":"2x"},
    {"size":"29x29","idiom":"iphone","filename":"Icon-App-29x29@3x.png","scale":"3x"},
    {"size":"40x40","idiom":"iphone","filename":"Icon-App-40x40@2x.png","scale":"2x"},
    {"size":"40x40","idiom":"iphone","filename":"Icon-App-40x40@3x.png","scale":"3x"},
    {"size":"60x60","idiom":"iphone","filename":"Icon-App-60x60@2x.png","scale":"2x"},
    {"size":"60x60","idiom":"iphone","filename":"Icon-App-60x60@3x.png","scale":"3x"},
    {"size":"20x20","idiom":"ipad","filename":"Icon-App-20x20@1x.png","scale":"1x"},
    {"size":"20x20","idiom":"ipad","filename":"Icon-App-20x20@2x.png","scale":"2x"},
    {"size":"29x29","idiom":"ipad","filename":"Icon-App-29x29@1x.png","scale":"1x"},
    {"size":"29x29","idiom":"ipad","filename":"Icon-App-29x29@2x.png","scale":"2x"},
    {"size":"40x40","idiom":"ipad","filename":"Icon-App-40x40@1x.png","scale":"1x"},
    {"size":"40x40","idiom":"ipad","filename":"Icon-App-40x40@2x.png","scale":"2x"},
    {"size":"76x76","idiom":"ipad","filename":"Icon-App-76x76@1x.png","scale":"1x"},
    {"size":"76x76","idiom":"ipad","filename":"Icon-App-76x76@2x.png","scale":"2x"},
    {"size":"83.5x83.5","idiom":"ipad","filename":"Icon-App-83_5x83_5@2x.png","scale":"2x"},
    {"size":"1024x1024","idiom":"ios-marketing","filename":"Icon-App-1024x1024@1x.png","scale":"1x"}
  ],
  "info" : {"version" : 1, "author" : "xcode"}
}
EOF

echo ""
echo "================================"
echo "✅ All icons generated successfully!"
echo "   Android: $ANDROID_BASE/mipmap-*/"
echo "   iOS:     $IOS_BASE/"
echo ""
echo "🔄 Now rebuild: flutter clean && flutter run"
