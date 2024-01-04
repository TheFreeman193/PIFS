# Copyright (C) MIT License 2023 Nicholas Bissell (TheFreeman193)
main() {
echo "
"
echo "===== PIFS Random Profile/Fingerprint Picker ====="
echo " (Buy me a coffee: https://ko-fi.com/nickbissell)"
echo "=================================================="
echo ""

# Test for root
if [ ! -d "/data/adb" ]; then
    echo "Can't touch /data/adb - this script needs to run as root on an Android device!"
    exit 1
fi

VERSION=120
RootDir="/data/adb/pifs"
FailedList="$RootDir/failed.lst"
ConfirmedDir="$RootDir/confirmed"
FailedDir="$RootDir/failed"
BackupDir="$RootDir/backups"

# Needed commands/shell functions
CMDS="cat
chmod
chown
cp
curl
date
find
grep
killall
mkdir
mv
rm
sed
unzip
wget"

if [ "$(command -v /data/adb/magisk/busybox)" ]; then
    BBOX="/data/adb/magisk/busybox"
elif [ "$(command -v /data/adb/ksu/bin/busybox)" ]; then
    BBOX="/data/adb/ksu/bin/busybox"
elif [ "$(command -v /sbin/.magisk/busybox/busybox)" ]; then
    BBOX="/sbin/.magisk/busybox/busybox"
elif [ "$(command -v /debug_ramdisk/.magisk/busybox/busybox)" ]; then
    BBOX="/debug_ramdisk/.magisk/busybox/busybox"
else
    LastHope="$(find /system \( -type f -o -type l \) -name busybox 2>/dev/null | head -n 1)"
    [ -z "$LastHope" ] && LastHope="$(find /data \( -type f -o -type l \) -name busybox 2>/dev/null | head -n 1)"
    [ -z "$LastHope" ] && [ -d "/bin" ] && LastHope="$(find /bin \( -type f -o -type l \) -name busybox 2>/dev/null | head -n 1)"
    [ -z "$LastHope" ] && [ -d "/usr" ] && LastHope="$(find /usr \( -type f -o -type l \) -name busybox 2>/dev/null | head -n 1)"
    [ -z "$LastHope" ] && [ -d "/sbin" ] && LastHope="$(find /sbin \( -type f -o -type l \) -name busybox 2>/dev/null | head -n 1)"
    [ -n "$LastHope" ] && BBOX="$LastHope" || BBOX=""
fi

if [ -n "$BBOX" ]; then
    # Use busybox
    echo "    Using busybox '$BBOX'"
    for acmd in $($BBOX --list | grep '[a-z0-9]'); do
        alias $acmd="$BBOX $acmd"
    done
else
    for acmd in "${CMDS[@]}"; do
        # Don't touch if command/builtin exists
        [ "$(command -v "$acmd")" ] && continue
        # Find bin paths
        tgt="$(find /system \( -type f -o -type l \) -name $acmd -print 2>/dev/null | head -n 1)"
        [ -z "$tgt" ] && tgt="$(find /data \( -type f -o -type l \) -name $acmd -print 2>/dev/null | head -n 1)"
        [ -z "$tgt" ] && tgt="$(find /bin \( -type f -o -type l \) -name $acmd -print 2>/dev/null | head -n 1)"
        [ -z "$tgt" ] && tgt="$(find /usr \( -type f -o -type l \) -name $acmd -print 2>/dev/null | head -n 1)"
        [ -z "$tgt" ] && tgt="$(find /sbin \( -type f -o -type l \) -name $acmd -print 2>/dev/null | head -n 1)"
        if [ -n "$tgt" ]; then
            alias $acmd="$tgt"
        elif [ "$acmd" != "curl" -a "$acmd" != "wget" ]; then
            echo "ERROR: Couldn't find bin path for command '$acmd'"
            exit 2
        fi
    done
    if ! [ "$(command -v wget)" -o "$(command -v curl)" ]; then
        echo "ERROR: Couldn't find bin path for 'curl' or 'wget'"
        exit 3
    fi
fi

# Check if interactive
INTERACTIVE=0
echo "$0" | grep 'pickaprint\.sh$' >/dev/null && INTERACTIVE=1

# Update check, disable with 'export PIFSNOUPDATE=1'
if [ -z "$PIFSNOUPDATE" ] && [ -d "./JSON" ] && [ ! -f ./JSON/VERSION -o $(cat ./JSON/VERSION) -lt $VERSION ]; then
    echo ""
    echo "New collection update available. Moving existing to PIFS_OLD.zip..."
    rm -r ./JSON # Remove old unpacked collection
    [ -f "./PIFS.zip" ] && mv ./PIFS.zip ./PIFS_OLD.zip # Move old repo archive
    # Triggers re-download below
fi

# Test if JSON dir exists
if [ ! -d "./JSON" ]; then
    # Check if repo ZIP exists
    if [ ! -f "./PIFS.zip" ]; then
        # Download repo archive
        echo ""
        echo "Downloading profile/fingerprint repo from GitHub..."
        dUrl="https://codeload.github.com/TheFreeman193/PIFS/zip/refs/heads/main"
        dTarget="PIFS.zip"
        # Handle many environments; usually curl or webget exist somewhere
        if [ "$(command -v wget)" ]; then
            wget -O "$dTarget" "$dUrl"
        elif [ "$(command -v curl)" ]; then
            curl -o "$dTarget" "$dUrl"
        else
            echo "WARNING: Couldn't find wget or curl to download the repository."
        fi
        if [ ! $? ] || [ ! -f "./PIFS.zip" ]; then
            if [ -f "./PIFS_OLD.zip" ]; then
                mv ./PIFS_OLD.zip ./PIFS.zip # Restore outdated copies
                echo "Restored outdated version from PIFS_OLD.zip"
            else
                echo "ERROR: Couldn't get repo. You'll have to download manually from https://github.com/TheFreeman193/PIFS"
                exit 4
            fi
        fi
    fi
    if [ ! -d "./JSON" ]; then
        if [ ! -f "./PIFS.zip" ]; then
            echo "ERROR: Repository archive PIFS.zip couldn't be downloaded"
            exit 5
        fi
        # Unzip repo archive
        echo ""
        echo "Extracting profiles/fingerprints from PIFS.zip..."
        unzip -qo PIFS.zip -x .git* -x README.md -x LICENSE
        # Copy JSON files
        mv ./PIFS-main/JSON .
        if [ ! -f "./pickaprint.sh" ]; then
            mv ./PIFS-main/pickaprint.sh .
        fi
        rm -r ./PIFS-main
    fi
fi

if [ -f "./pickaprint.sh" ]; then
    chown root:root ./pickaprint.sh
    chmod 755 ./pickaprint.sh
fi

[ ! -d "$RootDir" ] && mkdir "$RootDir"

# Migrate old versions
[ ! -d "$BackupDir" ] && [ -d "/data/adb/oldpifs" ] && mv "/data/adb/oldpifs" "$BackupDir"
[ ! -f "$FailedList" ] && [ -f "/data/adb/failedpifs.lst" ] && mv "/data/adb/failedpifs.lst" "$FailedList"

[ ! -d "$ConfirmedDir" ] && mkdir "$ConfirmedDir"
[ ! -d "$FailedDir" ] && mkdir "$FailedDir"
[ ! -d "$BackupDir" ] && mkdir "$BackupDir"
[ ! -f "$FailedList" ] && touch "$FailedList"

# Check which module installed, fall back to data/adb/pif.json
echo ""
echo "Looking for installed PIF module..."
Author=$(cat /data/adb/modules/playintegrityfix/module.prop | grep "author=" | sed -r 's/author=([^ ]+) ?.*/\1/gi')
if [ -z "$Author" ]; then
    echo "    Can't detect an installed PIF module! Will use /data/adb/pif.json"
    Target="/data/adb/pif.json"
elif [ "$Author" == "chiteroman" ]; then
    echo "    Detected chiteroman module. Will use /data/adb/pif.json"
    Target="/data/adb/pif.json"
elif [ "$Author" == "osm0sis" ]; then
    echo "    Detected osm0sis module. Will use /data/adb/modules/playintegrityfix/custom.pif.json"
    Target="/data/adb/modules/playintegrityfix/custom.pif.json"
else
    echo "    PIF module found but not recognized! Will use /data/adb/pif.json"
    Target="/data/adb/pif.json"
fi

# Add exclusion from current PIF fingerprint if requested with -x
if [ "$(echo "$*" | grep -e "-[a-z]*x")" ]; then
    if [ -f "$Target" ]; then
        FPToExclude="$(cat "$Target" | grep '"FINGERPRINT":' | sed -r 's/.*"FINGERPRINT" *: *"(.+)".*/\1.json/ig;s/[^a-z0-9_.\-]/_/gi')"
        if [ -n "$FPToExclude" ]; then
            echo ""
            echo "Adding profile '$FPToExclude' to failed list..."
            echo "$FPToExclude" >> "$FailedList"
            rm "$Target"
        fi
    else
        echo "Profile '$Target' doesn't exist - nothing to exclude"
    fi
fi

FList=""
# Optionally pick only confirmed profiles
if [ "$(echo "$*" | grep -e "-[a-z]*c")" ]; then
    if [ -d "$ConfirmedDir" ]; then
        FList=$(find "$ConfirmedDir" -type f -name "*.json")
    else
        echo "WARNING: -c argument present but '$ConfirmedDir' directory doesn't exist"
    fi
    if [ -n "$FList" ]; then
        SearchPath="$ConfirmedDir"
    else
        echo "WARNING: No profiles/fingerprints found in '$ConfirmedDir'"
    fi
fi

# Allow overrides, enable with 'export FORCEABI="<abi_list>"'
if [ -z "$FList" ] && [ -n "$FORCEABI" ]; then
    echo ""
    if [ -d "./JSON/$FORCEABI" ]; then
        echo "\$FORCEABI is set, will only pick profile from '${FORCEABI}'"
        # Get files in overridden dir
        FList=$(find "./JSON/$FORCEABI" -type f -name "*.json")
    else
        echo "WARNING: \$FORCEABI set but dir '$FORCEABI' doesn't exist in ./JSON"
    fi
    if [ -n "$FList" ]; then
        SearchPath="./JSON/$FORCEABI"
    else
        echo "WARNING: No profiles/fingerprints found for ABI list '${FORCEABI}'"
    fi
fi

if [ -z "$FList" ]; then
    # Get compatible ABIs from build props
    echo ""
    echo "Detecting device ABI list..."
    ABIList="$(getprop | grep -E '\[ro\.product\.cpu\.abilist\]: \[' | sed -r 's/\[[^]]+\]: \[(.+)\]/\1/g')"
    if [ -z "$ABIList" ]; then # Old devices had single string prop for this
        ABIList="$(getprop | grep -E '\[ro\.product\.cpu\.abi\]: \[' | sed -r 's/\[[^]]+\]: \[(.+)\]/\1/g')"
    fi
    # Get files from detected dir, else try all dirs
    if [ -n "$ABIList" ]; then
        echo "    Will use profile/fingerprint with ABI list '${ABIList}'"
        FList=$(find "./JSON/${ABIList}" -type f -name "*.json")
        if [ -n "$FList" ]; then
            SearchPath="./JSON/$ABIList"
        else
            echo "WARNING: No profiles/fingerprints found for ABI list '$ABIList'"
        fi
    else
        echo "WARNING: Couldn't detect ABI list."
    fi
fi

# Ensure we don't get empty lists, fall back to all dirs
if [ -z "$FList" ]; then
    echo "    Will use profile/fingerprint from entire ./JSON directory."
    FList=$(find ./JSON -type f -name "*.json")
    if [ -n "$FList" ]; then
        SearchPath="./JSON"
    fi
fi

if [ -z "$FList" ]; then
    echo "ERROR: Couldn't find any profiles/fingerprints. Is the $PWD/JSON directory empty?"
    exit 8
fi



while true; do

    # Count JSON files in list
    FCount=$(echo "$FList" | wc -l)
    if [ $FCount == 0 ]; then
        echo "ERROR: Couldn't parse JSON file list!"
        exit 9
    fi

    # Get random device profile from file list excluding previously failed
    echo ""
    echo "Picking a random profile/fingerprint..."
    MAX=10
    Counter=0
    while [ $Counter -lt $MAX ]; do
        Counter=$((Counter + 1))
        RandFPNum=$((1 + ($RANDOM * 2) % $FCount)) # Get a random index from the list
        RandFP=$(echo "$FList" | sed -r "${RandFPNum}q;d") # Get path of random index
        if [ ! -f "$RandFP" ]; then
            FList=$(find "$SearchPath" -type f -name "*.json")
            FCount=$(echo "$FList" | wc -l)
            continue 1
        fi
        FName=$(basename "$RandFP") # Resolve filename
        if [ "$(echo "$FName" | grep -xFf "$FailedList")" ]; then # Check exclusions list
            echo "    Found excluded profile '$FName'. Moving to '$FailedDir'"
            mv "$RandFP" "$FailedDir/$FName"
        else
            break
        fi
    done

    if [ $Counter -ge $MAX ]; then
        echo "ERROR: Exhausted $MAX attempts to pick a profile not in the failed list. Are all profiles excluded?"
        exit 10
    fi

    echo ""
    echo "    Profile: '${RandFP/ /}'"

    # Back up old profiles
    if [ -f "${Target}" ]; then
        if [ ! -d "$BackupDir" ]; then
            mkdir "$BackupDir"
        fi
        BackupFName="$(cat "$Target" | grep '"FINGERPRINT":' | sed -r 's/.*"FINGERPRINT" *: *"(.+)".*/\1.json/ig;s/[^a-z0-9_.\-]/_/gi')"
        [ -z "$BackupFName" ] && BackupFName="$(date +%Y%m%dT%H%M%S).json"
        echo ""
        if [ "$(echo "$BackupFName" | grep -xFf "$FailedList")" ]; then
            echo "Profile '$BackupFName' is in failed list - won't back up"
            rm "$Target"
        else
            echo "Backing up current profile to '$BackupDir/$BackupFName'..."
            mv "${Target}" "$BackupDir/$BackupFName"
        fi
    fi

    # Copy random FP
    echo ""
    echo "Copying profile to ${Target}..."
    cp "${RandFP}" "${Target}"

    # Default first SDK version

    # Alternate key names
    if [ "$Author" = "chiteroman" ]; then
        echo "    Converting pif.json to chiteroman format..."
        sed -i -r 's/("DEVICE_INITIAL_SDK_INT": *)(""|0|null)/\1"25"/ig
        s/("DEVICE_INITIAL_SDK_INT": )([0-9]+),/\1"\2"/ig
        s/"DEVICE_INITIAL_SDK_INT":/"FIRST_API_LEVEL":/ig
        /^[[:space:]]*"\*.+$/d
        /^[[:space:]]*"[^"]*\..+$/d
        /^[[:space:]]*"(ID|RELEASE_OR_CODENAME|INCREMENTAL|TYPE|TAGS|SDK_INT|RELEASE)":.+$/d
        /^[[:space:]]*$/d' "$Target"
    else
        sed -i -r 's/("(DEVICE_INITIAL_SDK_INT|\*api_level)": *)(""|0|null)/\125/ig' "$Target"
    fi

    # Kill GMS unstable to force new values
    echo ""
    echo "Killing GMS unstable process..."
    killall com.google.android.gms.unstable

    echo ""
    echo "===== Test your Play Integrity now ====="
    echo ""

    if [ $INTERACTIVE -eq 1 ]; then
        INPUT=""
        while true; do
            echo ""
            echo -n "Did the profile pass both BASIC and DEVICE integrity? (y/n/c): "
            read -r INPUT
            case "$INPUT" in
                y)
                    echo "Copying '$FName' to '$ConfirmedDir'"
                    echo ""
                    echo "Tip: You can use './pickaprint.sh -c' to try only confirmed profiles"
                    cp "$RandFP" "$ConfirmedDir"
                    break 2
                ;;
                n)
                    echo "Excluding '$FName'"
                    echo "$FName" >> "$FailedList"
                    mv "$RandFP" "$FailedDir/$FName"
                    rm "$Target"
                    [ -f "$ConfirmedDir/$FName" ] && rm "$ConfirmedDir/$FName"
                    break
                ;;
                c)
                    echo "Exiting immediately."
                    exit 0
                ;;
                *)
                    echo "Invalid input"
                ;;
            esac
        done
    else
        echo "NOTE: As the script was piped or dot-sourced, the interactive mode can't work."
        echo "If this profile didn't work, run the script locally with -x using:"
        echo "    ./pickaprint.sh -x"
        echo "Or manually add the profile to the failed list:"
        echo "    echo '$FName' >> '$FailedList'"
        echo ""
        echo "If the profile works, you can copy it to the confirmed directory with:"
        echo "    cp '$RandFP' '$ConfirmedDir'"
        echo "To use only confirmed profiles, run the script with -c:"
        echo "    ./pickaprint.sh -c"
        break
    fi

done

echo ""
echo "Finished!"
}
main $*
