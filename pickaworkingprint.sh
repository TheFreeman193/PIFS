#!/system/bin/sh
cd "$(dirname "$0")"

(
# Copyright (C) MIT License 2023 Nicholas Bissell (TheFreeman193)
echo "\n===== PIFS Random Profile/Fingerprint Picker ====="

if [ ! -d "/data/adb" ]; then
    echo "Can't touch /data/adb - this script needs to run as root!"
    exit 1
fi

if [ ! -d "./works_for_me" ]; then
    echo "No working folder found."
    exit 2
else
    echo "Selecting a working print..."
    FList=$(find ./works_for_me -type f)
    if [ -z "$FList" ]; then
        echo "Couldn't find any profiles/fingerprints. Is the $PWD/works_for_me directory empty?"
        exit 3
    fi
fi

FCount=$(echo "$FList" | wc -l)
if [ $FCount == 0 ]; then
    echo "Couldn't parse JSON file list!"
    exit 4
fi

echo "Picking a random profile/fingerprint..."
RandFPNum=$((1 + ($RANDOM * 2) % $FCount)) # Get a random index from the list
RandFP=$(echo "$FList" | sed -r "${RandFPNum}q;d") # Get path of random index

echo "\nRandom profile/fingerprint file: '${RandFP/ /}'\n"

echo "Looking for installed PIF module..."

# Check which module installed
Author=$(cat /data/adb/modules/playintegrityfix/module.prop | grep "author=" | sed -r 's/author=([^ ]+) ?.*/\1/g')
if [ -z "$Author" ]; then
    echo "Can't detect an installed PIF module! Will use /data/adb/pif.json"
    Target="/data/adb/pif.json"
elif [ $Author == "chiteroman" ]; then
    echo "Detected chiteroman module. Will use /data/adb/pif.json"
    Target="/data/adb/pif.json"
elif [ $Author == "osm0sis" ]; then
    echo "Detected osm0sis module. Will use /data/adb/modules/playintegrityfix/custom.pif.json"
    Target="/data/adb/modules/playintegrityfix/custom.pif.json"
else
    echo "PIF module found but not recognized! Will use /data/adb/pif.json"
    Target="/data/adb/pif.json"
fi

echo "Copying JSON to ${Target}..."
cp "${RandFP}" "${Target}"

echo "Killing GMS unstable process..."
killall com.google.android.gms.unstable

echo "\n===== Done. Test your Play Integrity now! ====="

exit 0
