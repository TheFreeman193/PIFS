# Copyright (C) MIT License 2023 Nicholas Bissell (TheFreeman193)
NL="
"
COLLECTION_VERSION=130
SCRIPT_VERSION=400
RootDir="/data/adb/pifs"
FailedFile="$RootDir/failed.lst"
ConfirmedDir="$RootDir/confirmed"
BackupDir="$RootDir/backups"
UserAgent="Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0"
ScriptVerUrl="https://raw.githubusercontent.com/TheFreeman193/PIFS/main/SCRIPT_VERSION"
ColVerUrl="https://raw.githubusercontent.com/TheFreeman193/PIFS/main/JSON/VERSION"
ScriptUrl="https://raw.githubusercontent.com/TheFreeman193/PIFS/main/pickaprint.sh"
CollectionUrl="https://codeload.github.com/TheFreeman193/PIFS/zip/refs/heads/main"
CollectionFile="./PIFS.zip"
BackupCollectionFile="./PIFS_OLD.zip"
JsonDir="./JSON"
ListFile="./pifs_file_list"

echo "$NL$NL==== PIFS Random Profile/Fingerprint Picker ===="
echo " Buy me a coffee: https://ko-fi.com/nickbissell"
echo "============= v4 - collection v1.3 =============$NL"

if [ "$(echo "$*" | grep -e "-[a-z]*[?h]" -e "--help")" ]; then
    echo "Usage: ./pickaprint.sh [-x] [-i] [-c] [-a] [-s] [-r[r]] [-h|?]$NL$NL"
    echo "  -x  Add existing pif.json/custom.pif.json profiles to exclusions and pick a print"
    echo "  -i  Add existing pif.json/custom.pif.json profiles to confirmed and exit"
    echo "  -c  Use only confirmed profiles from '$ConfirmedDir'"
    echo "  -a  Pick profile from entire JSON directory - overrides \$FORCEABI"
    echo "  -s  Add additional 'SDK_INT'/'*.build.version.sdk' props to profile"
    echo "  -r  Reset - removes all settings/lists/collection (except confirmed directory)"
    echo "  -rr Completely remove - as Reset but removes confirmed and script file"
    echo "  -h  Display this help message$NL"
    exit 0
fi

# Test for root
if [ ! -d "/data/adb" ]; then
    echo "Can't touch /data/adb - this script needs to run as root on an Android device!"
    exit 1
fi

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

# API/SDK level reference
ApiLevels="14=34
13=33
12=31
11=30
10=29
9=28
8.1=27
8.0=26
7.1 7.1.1 7.1.2=25
7.0=24
6.0 6.0.1=23
5.1 5.1.1=22
5.0 5.0.1 5.0.2=21
4.4W 4.4W.1 4.4W.2=20
4.4 4.4.1 4.4.2 4.4.3 4.4.4=19
4.3 4.3.1=18
4.2 4.2.1 4.2.2=17
4.1 4.1.1 4.1.2=16
4.0.3 4.0.4=15
4.0 4.0.1 4.0.2=14
3.2 3.2.1 3.2.2 3.2.4 3.2.6=13
3.1=12
3.0=11
2.3.3 2.3.4 2.3.5 2.3.6 2.3.7=10
2.3 2.3.1 2.3.2=9
2.2 2.2.1 2.2.2 2.2.3=8
2.1=7
2.0.1=6
2.0=5
1.6=4
1.5=3
1.1=2
1.0=1"

ROOTMODE=""

if [ "$(command -v /data/adb/magisk/busybox)" ]; then
    BBOX="/data/adb/magisk/busybox"
    ROOTMODE="Magisk"
elif [ "$(command -v /data/adb/ksu/bin/busybox)" ]; then
    BBOX="/data/adb/ksu/bin/busybox"
    ROOTMODE="KSU"
elif [ "$(command -v /sbin/.magisk/busybox/busybox)" ]; then
    BBOX="/sbin/.magisk/busybox/busybox"
    ROOTMODE="Magisk"
elif [ "$(command -v /debug_ramdisk/.magisk/busybox/busybox)" ]; then
    BBOX="/debug_ramdisk/.magisk/busybox/busybox"
    ROOTMODE="KSU"
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
echo "$0" | grep 'pickaprint\.sh$' >/dev/null && INTERACTIVE=1 && cd "$(dirname "$0")"

# Reset/remove if requested with -r
RESET_CONFIRM="/data/adb/pifs/CONFIRM_RESETREMOVE"
if [ "$(echo "$*" | grep -e "-[a-z]*r")" ]; then
    if [ ! -f "$RESET_CONFIRM" ]; then
        echo "${NL}Running with -r or -rr will permanently delete PIFS settings. Run again to confirm."
        touch "$RESET_CONFIRM"
        exit 0
    fi
    echo "${NL}Removing all PIFS settings, lists, and local collection..."
    [ -d "$JsonDir" ] && rm -r "$JsonDir"
    [ -f "$CollectionFile" ] && rm "$CollectionFile"
    [ -f "$BackupCollectionFile" ] && rm "$BackupCollectionFile"
    [ -d "$RootDir/failed" ] && rm -r "$RootDir/failed"
    [ -d "$BackupDir" ] && rm -r "$BackupDir"
    [ -f "$FailedFile" ] && rm "$FailedFile"
    if [ "$(echo "$*" | grep -e "-[a-z]*rr")" ]; then
        echo "Removing confirmed directory and pickaprint.sh script..."
        [ -d "$ConfirmedDir" ] && rm -r "$ConfirmedDir"
        [ -d "$RootDir" ] && [ "$(ls "$RootDir")" = "" ] && rm -r "$RootDir"
        if [ "$INTERACTIVE" -eq 1 ]; then
            [ -f "$0" ] && rm -f "$0"
        else
            [ -f "./pickaprint.sh" ] && rm -f "./pickaprint.sh"
        fi
    fi
    rm -f "$RESET_CONFIRM"
    exit 0
fi
[ -f "$RESET_CONFIRM" ] && rm -f "$RESET_CONFIRM"

# Update check, disable with 'export PIFSNOUPDATE=1'
if [ -z "$PIFSNOUPDATE" ]; then
    echo "${NL}Checking for new version...${NL}    Tip: You can disable this check with 'export PIFSNOUPDATE=1'"

    if [ "$(command -v wget)" ]; then
        ONLINEVERSION="$(wget -O - -U "$UserAgent" --no-check-certificate "$ScriptVerUrl" 2>/dev/null)"
        ONLINECOLLECTIONVERSION="$(wget -O - -U "$UserAgent" --no-check-certificate "$ColVerUrl" 2>/dev/null)"
    elif [ "$(command -v curl)" ]; then
        ONLINEVERSION="$(curl -k -A "$UserAgent" "$ScriptVerUrl" 2>/dev/null)"
        ONLINECOLLECTIONVERSION="$(curl -k -A "$UserAgent" "$ColVerUrl" 2>/dev/null)"
    else
        echo "WARNING: Couldn't find wget or curl to check for latest version."
    fi
    if [ -n "$ONLINEVERSION" ] && [ "$ONLINEVERSION" -gt $SCRIPT_VERSION ]; then
        echo "$NL================================================"
        echo "A newer version of the script is available.${NL}Download with:$NL"
        if [ "$ROOTMODE" == "Magisk" ]; then
            echo "/data/adb/magisk/busybox wget -O pickaprint.sh \"$ScriptUrl\""
        elif [ "$ROOTMODE" == "KSU" ]; then
            echo "/data/adb/ksu/bin/busybox wget -O pickaprint.sh \"$ScriptUrl\""
        else
            echo "curl -o pickaprint.sh \"$ScriptUrl\""
        fi
        echo "================================================$NL"
    fi
    [ -n "$ONLINECOLLECTIONVERSION" ] && COLLECTION_VERSION=$ONLINECOLLECTIONVERSION
    if [ -d "$JsonDir" ] && [ ! -f "$JsonDir/VERSION" -o $(cat "$JsonDir/VERSION") -lt $COLLECTION_VERSION ]; then
        echo "${NL}There is an updated collection available. Moving existing to $BackupCollectionFile..."
        rm -r "$JsonDir" # Remove old unpacked collection
        [ -f "$CollectionFile" ] && mv "$CollectionFile" "$BackupCollectionFile" # Move old repo archive
        # Triggers re-download below
    fi
else
    echo "${NL}\$PIFSNOUPDATE is set - offline mode"
fi

# Test if JSON dir exists
if [ ! -d "$JsonDir" ]; then
    # Check if repo ZIP exists
    if [ ! -f "$CollectionFile" ]; then
        if [ -n "$PIFSNOUPDATE" ]; then
            echo "Neither collection '$JsonDir' nor archive '$CollectionFile' found but \$PIFSNOUPDATE is set. Stopping."
            exit 0
        fi
        # Download repo archive
        echo "${NL}Downloading profile/fingerprint collection from GitHub..."
        # Handle many environments; usually curl or webget exist somewhere
        if [ "$(command -v wget)" ]; then
            wget -O "$CollectionFile" --no-check-certificate "$CollectionUrl" >/dev/null 2>&1
        elif [ ! -f "$CollectionFile" ] && [ "$(command -v curl)" ]; then
            curl -ko "$CollectionFile" "$CollectionUrl" >/dev/null 2>&1
        else
            echo "WARNING: Couldn't find wget or curl to download the repository."
        fi
        if [ ! -f "$CollectionFile" ]; then
            if [ -f "$BackupCollectionFile" ]; then
                mv "$BackupCollectionFile" "$CollectionFile" # Restore outdated copies
                echo "Restored outdated version from $BackupCollectionFile"
            else
                echo "ERROR: Couldn't get repo. You'll have to download manually from https://github.com/TheFreeman193/PIFS"
                exit 4
            fi
        fi
    fi
    if [ ! -d "$JsonDir" ]; then
        if [ ! -f "$CollectionFile" ]; then
            echo "ERROR: Repository archive $CollectionFile couldn't be downloaded"
            exit 5
        fi
        # Unzip repo archive
        echo "${NL}Extracting profiles/fingerprints from $CollectionFile..."
        unzip -qo "$CollectionFile" -x .git* -x README.md -x LICENSE
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
[ ! -f "$FailedFile" ] && [ -f "/data/adb/failedpifs.lst" ] && mv "/data/adb/failedpifs.lst" "$FailedFile"

[ ! -d "$ConfirmedDir" ] && mkdir "$ConfirmedDir"
[ ! -d "$BackupDir" ] && mkdir "$BackupDir"
[ ! -f "$FailedFile" ] && touch "$FailedFile"

# Check which module installed, fall back to data/adb/pif.json
echo "${NL}Looking for installed PIF module..."
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

if [ "$(echo "$*" | grep -e "-[a-z]*[ix]")" ] && [ -f "$Target" ]; then
    TargetName="$(cat "$Target" | grep '"FINGERPRINT":' | sed -r 's/.*"FINGERPRINT" *: *"(.+)".*/\1.json/ig;s/[^a-z0-9_.\-]/_/gi')"
    [ -z "$TargetName" ] && TargetName="$(date +%Y%m%dT%H%M%S).json"
fi

# Add to confirmed and exit if requested with -i
if [ "$(echo "$*" | grep -e "-[a-z]*i")" ]; then
    if [ -f "$Target" ] && [ -n "$TargetName" ]; then
        echo "${NL}Copying '$Target' to '$ConfirmedDir/$TargetName'..."
        cp "$Target" "$ConfirmedDir/$TargetName"
    else
        echo "Profile '$Target' doesn't exist - can't add it to confirmed"
    fi
    exit 0
fi

# Add exclusion from current PIF fingerprint if requested with -x
if [ "$(echo "$*" | grep -e "-[a-z]*x")" ]; then
    if [ -f "$Target" ] && [ -n "$TargetName" ]; then
        echo "${NL}Adding profile '$TargetName' to failed list..."
        echo "$TargetName" >> "$FailedFile"
        rm "$Target"
    else
        echo "Profile '$Target' doesn't exist - nothing to exclude"
    fi
fi

# Clean failed file
sed -ir "/^ *$/d" "$FailedFile"

# Pick from all profiles if requested with -a
FList=""
SearchPath=""
if [ "$(echo "$*" | grep -e "-[a-z]*a")" ]; then
    echo "${NL}-a present. Using entire JSON directory."
    FList="$(find "$JsonDir" -type f -name "*.json" | grep -vFf "$FailedFile")"
    if [ -z "$FList" ]; then
        echo "ERROR: No profiles/fingerprints found in '$JsonDir' that aren't excluded"
        exit 6
    fi
    SearchPath="$JsonDir"
fi

# Pick only from confirmed profiles if requested with -c
CONFIRMEDONLY=0
if [ -z "$SearchPath" ] && [ "$(echo "$*" | grep -e "-[a-z]*c")" ]; then
    CONFIRMEDONLY=1
    if [ -d "$ConfirmedDir" ]; then
        FList=$(find "$ConfirmedDir" -type f -name "*.json" | grep -vFf "$FailedFile")
    else
        echo "ERROR: -c argument present but '$ConfirmedDir' directory doesn't exist"
        exit 10
    fi
    if [ -n "$FList" ]; then
        SearchPath="$ConfirmedDir"
    else
        echo "ERROR: No profiles/fingerprints found in '$ConfirmedDir' that aren't excluded"
        exit 10
    fi
fi

# Allow overrides, enable with 'export FORCEABI="<abi_list>"'
if [ -z "$SearchPath" ] && [ -n "$FORCEABI" ]; then
    if [ -d "$JsonDir/$FORCEABI" ]; then
        echo "${NL}\$FORCEABI is set, will only pick profile from '${FORCEABI}'"
        # Get files in overridden dir
        FList=$(find "$JsonDir/$FORCEABI" -type f -name "*.json" | grep -vFf "$FailedFile")
    else
        echo "${NL}ERROR: \$FORCEABI set but dir '$FORCEABI' doesn't exist in $JsonDir"
        exit 7
    fi
    if [ -n "$FList" ]; then
        SearchPath="$JsonDir/$FORCEABI"
    else
        echo "${NL}ERROR: No profiles/fingerprints found in '$JsonDir/$FORCEABI' that aren't excluded"
        exit 7
    fi
fi

if [ -z "$SearchPath" ]; then
    # Get compatible ABIs from build props
    echo "${NL}Detecting device ABI list..."
    ABIList="$(getprop | grep -E '\[ro\.product\.cpu\.abilist\]: \[' | sed -r 's/\[[^]]+\]: \[(.+)\]/\1/g')"
    if [ -z "$ABIList" ]; then # Old devices had single string prop for this
        ABIList="$(getprop | grep -E '\[ro\.product\.cpu\.abi\]: \[' | sed -r 's/\[[^]]+\]: \[(.+)\]/\1/g')"
    fi
    # Get files from detected dir, else try all dirs
    if [ -n "$ABIList" ]; then
        echo "    Will use profile/fingerprint with ABI list '${ABIList}'"
        FList=$(find "$JsonDir/${ABIList}" -type f -name "*.json" | grep -vFf "$FailedFile")
        if [ -n "$FList" ]; then
            SearchPath="$JsonDir/$ABIList"
        else
            echo "WARNING: No profiles/fingerprints found for ABI list '$ABIList'"
        fi
    else
        echo "WARNING: Couldn't detect ABI list."
    fi
fi

# Ensure we don't get empty lists, fall back to all dirs
if [ -z "$SearchPath" ]; then
    echo "    Will use profile/fingerprint from entire $JsonDir directory."
    FList=$(find "$JsonDir" -type f -name "*.json" | grep -vFf "$FailedFile")
    if [ -n "$FList" ]; then
        SearchPath="$JsonDir"
    fi
fi

if [ -z "$SearchPath" ]; then
    echo "ERROR: Couldn't find any profiles/fingerprints. Is the $PWD/JSON directory empty?"
    exit 8
fi

while true; do

    find "$SearchPath" -type f -name "*.json" | grep -vFf "$FailedFile" > "$ListFile"

    # Count JSON files in list
    FCount=0
    [ -f "$ListFile" ] && FCount="$(sed -n '$=' "$ListFile")"
    if [ -z "$FCount" ] || [ "$FCount" -eq 0 ]; then
        echo "${NL}ERROR: No profiles/fingerprints found in '$SearchPath' that aren't excluded"
        [ -f "$ListFile" ] && rm -f "$ListFile"
        exit 9
    fi

    # Get random device profile from file list excluding previously failed
    [ "$CONFIRMEDONLY" -eq 1 ] && echo "${NL}Picking a random confirmed profile/fingerprint..." \
    || echo "${NL}Picking a random profile/fingerprint..."
    RandFPNum=$((1 + ($RANDOM * 2) % $FCount)) # Get a random index from the list
    RandFP="$(sed -r "${RandFPNum}q;d" "$ListFile")" # Get path of random index
    rm -f "$ListFile"
    FName=$(basename "$RandFP") # Resolve filename

    # Back up old profiles
    if [ -f "${Target}" ]; then
        if [ ! -d "$BackupDir" ]; then
            mkdir "$BackupDir"
        fi
        BackupFName="$(cat "$Target" | grep '"FINGERPRINT":' | sed -r 's/.*"FINGERPRINT" *: *"(.+)".*/\1.json/ig;s/[^a-z0-9_.\-]/_/gi')"
        [ -z "$BackupFName" ] && BackupFName="$(date +%Y%m%dT%H%M%S).json"
        if [ "$(echo "$BackupFName" | grep -xFf "$FailedFile")" ]; then
            echo "${NL}Profile '$BackupFName' is in failed list - won't back up"
            rm "$Target"
        elif [ ! -f "$BackupDir/$BackupFName" ]; then
            echo "${NL}Backing up old profile to '$BackupDir'..."
            mv "${Target}" "$BackupDir/$BackupFName"
        fi
        echo "${NL}    Old Profile: '${BackupFName/ /}'"
    fi

    echo "${NL}    New Profile: '${FName/ /}'"

    # Copy random FP
    echo "${NL}Copying profile to ${Target}..."
    cp "${RandFP}" "${Target}"

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

    # Restore SDK level props if requested
    if [ "$(echo "$*" | grep -e "-[a-z]*s")" ]; then
        RELEASE="$(cat "$Target" | grep '"FINGERPRINT":' | sed -r 's/ *"FINGERPRINT": *"[^\/]*\/[^\/]*\/[^\/:]*:([^\/]+).*$/\1/g')"
        SDKLevel="$(echo "$ApiLevels" | grep "$RELEASE" | sed -r 's/.+=//g')"
        sed -i -r -e "/\{/a\ \ \"SDK_INT\": \"$SDKLevel\"," -e "/\{/a\ \ \"*.build.version.sdk\": \"$SDKLevel\"," "$Target"
    fi

    # Kill GMS unstable to force new values
    echo "${NL}Killing GMS unstable process..."
    killall com.google.android.gms.unstable >/dev/null 2>&1

    echo "${NL}===== Test your Play Integrity now =====$NL"

    if [ "$INTERACTIVE" -eq 1 ]; then
        INPUT=""
        while true; do
            echo -n "${NL}Did the profile pass both BASIC and DEVICE integrity? (y/n/c): "
            read -r INPUT
            case "$INPUT" in
                y)
                    if [ "$CONFIRMEDONLY" -ne 1 ]; then
                        echo "Copying '$FName' to '$ConfirmedDir'"
                        echo "${NL}Tip: You can use './pickaprint.sh -c' to try only confirmed profiles"
                        cp "$RandFP" "$ConfirmedDir"
                    fi
                    break 2
                ;;
                n)
                    echo "Excluding '$FName'"
                    echo "$FName" >> "$FailedFile"
                    sed -ir "/^ *$/d" "$FailedFile"
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
        echo "    echo '$FName' >> '$FailedFile'"
        echo "${NL}If the profile works, you can copy it to the confirmed directory with:"
        echo "    cp '$RandFP' '$ConfirmedDir'"
        echo "To use only confirmed profiles, run the script with -c:"
        echo "    ./pickaprint.sh -c"
        break
    fi

done

echo "${NL}Finished!"
