#!/bin/bash
set -e

DIR="/Users/musamasalla/Library/Mobile Documents/com~apple~CloudDocs/Cursor/New Projects/SoberSend/iOS/SoberSend/SoberSend/Assets.xcassets/AppIcon.appiconset"
SRC="$DIR/icon-1024.png"

# Define sizes
SIZES=(20 29 40 60 76 83.5 1024)
SCALES_20=(1 2 3)
SCALES_29=(1 2 3)
SCALES_40=(1 2 3)
SCALES_60=(2 3)
SCALES_76=(1 2)
SCALES_835=(2)
SCALES_1024=(1)

rm -f "$DIR"/Contents.json

echo "{" >> "$DIR"/Contents.json
echo "  \"images\" : [" >> "$DIR"/Contents.json

generate_icon() {
    base=$1
    scale=$2
    idiom=$3
    size=$(echo "$base * $scale" | bc)
    size=${size%.*} # remove decimal if any
    
    filename="icon-${base}x${base}@${scale}x.png"
    if [ "$scale" == "1" ]; then
        filename="icon-${base}x${base}.png"
    fi
    if [ "$base" == "1024" ]; then
        filename="icon-1024.png"
    fi
    
    if [ "$base" != "1024" ]; then
        sips -z $size $size "$SRC" --out "$DIR/$filename" > /dev/null
    fi
    
    echo "    {" >> "$DIR"/Contents.json
    echo "      \"filename\" : \"$filename\"," >> "$DIR"/Contents.json
    echo "      \"idiom\" : \"$idiom\"," >> "$DIR"/Contents.json
    echo "      \"scale\" : \"${scale}x\"," >> "$DIR"/Contents.json
    
    # format float bases correctly
    if [ "$base" == "83.5" ]; then
        echo "      \"size\" : \"83.5x83.5\"" >> "$DIR"/Contents.json
    else
        echo "      \"size\" : \"${base}x${base}\"" >> "$DIR"/Contents.json
    fi
    
    echo "    }," >> "$DIR"/Contents.json
}

# iOS sizes (iPhone & iPad combined idioms for simplicity)
for s in 1 2 3; do generate_icon 20 $s "ios"; done # Actually 20x20 is just ipad for 1x, iphone/ipad for 2x/3x. Let's just generate a full standard json

# This is tedious. Let's just use a standard exhaustive template and generic sips resizer
