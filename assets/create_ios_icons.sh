#!/bin/sh

# For the convert commandline tool, first install brew cask:
# https://brew.sh/
# Then install ImageMagick via:
# brew install imagemagick

set -e

orig="appicon.png"
new_prefix="appicon_"

if [ ! -e "$orig" ]; then
    echo "Can't find $orig, you should export it from the Sketch file."
    echo "Exiting."
    exit 1
fi

iphone_settings="58 87"
iphone_spotlight="80 120"
iphone_app="120 180"

ipad_settings="29 58"
ipad_spotlight="40 80"
ipad_app="76 152"
ipad_pro_app="167"

iphone_ipad_notification="20 40 60"

app_store_icons="512 1024"

for i in $iphone_settings $iphone_spotlight $iphone_app $ipad_settings $ipad_spotlight $ipad_app $ipad_pro_app $app_store_icons $iphone_ipad_notification; do
    echo "Resizing to $i x $i"
    convert -resize $i $orig ${new_prefix}${i}.png
done

