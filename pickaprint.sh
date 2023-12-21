#!/bin/sh

(
# Copyright (C) MIT License 2023 Nicholas Bissell (TheFreeman193)
echo "\n===== PIFS Random Profile/Fingerprint Picker ====="

if [ ! -d "/data/adb" ]; then
    echo "Can't touch /data/adb - this script needs to run as root!"
    exit 1
fi

if [ ! -d "./JSON" ]; then
    if [ ! -f "./PIFS.zip" ]; then
        echo "Downloading profile/fingerprint repo from GitHub..."
        dUrl="https://codeload.github.com/TheFreeman193/PIFS/zip/refs/heads/main"
        dTarget="PIFS.zip"
        if [ $(command -v curl) ]; then
            curl -o "$dTarget" "$dUrl"
        elif [ $(command -v wget) ]; then
            wget -O "$dTarget" "$dUrl"
        elif [ $(command -v /system/bin/curl) ]; then
            /system/bin/curl -o "$dTarget" "$dUrl"
        elif [ $(command -v /system/bin/wget) ]; then
            /system/bin/wget -O "$dTarget" "$dUrl"
        elif [ $(command -v /data/data/com.termux/files/usr/bin/curl) ]; then
            /data/data/com.termux/files/usr/bin/curl -o "$dTarget" "$dUrl"
        elif [ $(command -v /data/data/com.termux/files/usr/include/curl) ]; then
            /data/data/com.termux/files/usr/include/curl -o "$dTarget" "$dUrl"
        elif [ $(command -v /data/adb/magisk/busybox) ]; then
            /data/adb/magisk/busybox wget -O "$dTarget" "$dUrl"
        elif [ $(command -v /debug_ramdisk/.magisk/busybox/wget) ]; then
            /debug_ramdisk/.magisk/busybox/wget -O "$dTarget" "$dUrl"
        elif [ $(command -v /sbin/.magisk/busybox/wget) ]; then
            /sbin/.magisk/busybox/wget -O "$dTarget" "$dUrl"
        elif [ $(command -v /system/xbin/wget) ]; then
            /system/xbin/wget -O "$dTarget" "$dUrl"
        elif [ $(command -v /system/xbin/curl) ]; then
            /system/xbin/curl -o "$dTarget" "$dUrl"
        else
            echo "Couldn't find wget or curl to download the repository.\nYou'll have to download it manually."
            exit 1
        fi
    fi
    echo "Extracting profiles/fingerprints from PIFS.zip..."
    unzip -o PIFS.zip -x .git* -x README.md -x LICENSE
    mv ./PIFS-main/JSON .
    mv ./PIFS-main/pickaprint.sh .
    rm -r ./PIFS-main
fi

if [ -v FORCEABI ]; then
    echo "\$FORCEABI is set, will only pick profile from '${FORCEABI}'"
    FList=$(find "./JSON/${FORCEABI}" -type f)
    if [ -z "$FList" ]; then
        echo "No profiles/fingerprints found for ABI list: '${FORCEABI}'."
        exit 2
    fi
else
    echo "Detecting device ABI list..."
    ABIList=$(getprop | grep -E '\[ro\.product\.cpu\.abilist\]: \[' | sed -r 's/\[[^]]+\]: \[(.+)\]/\1/')
    if [ -z "$ABIList" ]; then # Old devices had single string prop for this
        ABIList=$(getprop | grep -E '\[ro\.product\.cpu\.abi\]: \[' | sed -r 's/\[[^]]+\]: \[(.+)\]/\1/')
    fi
    if [ -n "$ABIList" ]; then
        echo "Will use profile/fingerprint with ABI list '${ABIList}'"
        FList=$(find "./JSON/${ABIList}" -type f)
    else
        echo "Couldn't detect ABI list. Will use profile/fingerprint from anywhere."
        FList=$(find ./JSON -type f)
    fi
    if [ -z "$FList" ]; then
        echo "No profiles/fingerprints found for ABI list: '${ABIList}'. Will use profile/fingerprint from anywhere."
        FList=$(find ./JSON -type f)
        if [ -z "$FList" ]; then
            echo "Couldn't find any profiles/fingerprints. Is the $PWD/JSON directory empty?"
            exit 3
        fi
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

# Back up old profiles
if [ -f "${Target}" ]; then
    if [ ! -d /data/adb/oldpifs ]; then
        mkdir /data/adb/oldpifs
    fi
    TStamp=$(date +%Y%m%dT%H%M%S)
    echo "Backing up current file to '/data/adb/oldpifs/${TStamp}.json'..."
    mv "${Target}" "/data/adb/oldpifs/${TStamp}.json"
fi

echo "Copying JSON to ${Target}..."
cp "${RandFP}" "${Target}"

echo "Killing GMS unstable process..."
killall com.google.android.gms.unstable

echo "\n===== Done. Test your Play Integrity now! ====="

)&  # Wrap for safety if piped from curl
exit 0
