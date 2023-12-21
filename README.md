# Play Integrity Fix Props Collection

## What is this?

This repository contains JSON files compatible with the [Play Integrity Fix](https://github.com/chiteroman/PlayIntegrityFix) module by [chiteroman](https://github.com/chiteroman/) or [PlayIntegrityFork](https://github.com/osm0sis/PlayIntegrityFork) made by [osm0sis](https://github.com/osm0sis).

If you don't use a custom ROM and haven't rooted your Android device, you're in the wrong place!

## Why is this needed?

By default, the PIF module and some of its forks use a default set of build properties (hereafter called a _profile_) including a build fingerprint for Play Integrity attestation.
With tens of thousands of users using the same profile, the Play Integrity servers inevitably block the associated fingerprint for software attestation.

The best solution in the meantime is for every user to choose a working profile (`pif.json` file) of their own.
Both the original PIF module and its major fork support this using a JSON file containing real properties from a working device.

## How do I choose a JSON file?

### Option 1: Using `pickaprint.sh`

This repository includes `pickaprint.sh` which automates the random selection of a profile with the same ABI compatibility as your device.
If piped directly from `curl`, it will download the PIFS repository, extract the JSON files, and pick one from the relevant folder at random.

In your favourite terminal emulator:

```sh
su # The script needs to be run as root in order to copy a profile to /data/adb
cd /storage/emulated/0 # Choose a place to download the collection
curl "https://raw.githubusercontent.com/TheFreeman193/PIFS/main/pickaprint.sh" | sh
```

Or in Termux:

```sh
/data/data/com.termux/files/usr/bin/curl "https://raw.githubusercontent.com/TheFreeman193/PIFS/main/pickaprint.sh" | sh
```

Or using Magisk's busybox:

```sh
/data/adb/magisk/busybox wget -O - "https://raw.githubusercontent.com/TheFreeman193/PIFS/main/pickaprint.sh" | sh
```

> **NOTE**: Please don't just run random scripts from the internet, especially as root.
> I strongly urge you to look at the script first and get a basic idea of what it does.

Once a subdirectory called `JSON` exists, the script will search for JSON profiles there instead of downloading the repository all over again.
This means you can either run the `curl` command above again, or run the script directly and the collection won't be re-downloaded.

To update the collection, delete the `JSON` directory that the script created and run the script again.

Alternatively, you could download/clone the repository and run the `pickaprint.sh` script directly from the download location.

### Option 2: Manually Selecting a File

> **Please choose a random file from the relevant directory.**
> Everyone picking the first or last file will inevitably result in that profile being blocked for software attestation.

The complete compatibility matrix for profiles and Android device isn't yet known - the Android ecosystem is huge and diverse, so this is to be expected.
It appears the list of ABIs your device supports needs to match the device the profile is from.

To test for this, enter the following in your favourite terminal emulator:

```sh
getprop | grep 'cpu\.abilist'
```

Or with ADB:

```sh
adb shell "getprop | grep 'cpu\.abilist'"
```

You should get a result that looks something like this:

```text
[ro.product.cpu.abilist]: [arm64-v8a,armeabi-v7a,armeabi]
[ro.product.cpu.abilist32]: [armeabi-v7a,armeabi]
[ro.product.cpu.abilist64]: [arm64-v8a]
[ro.system.product.cpu.abilist]: [arm64-v8a,armeabi-v7a,armeabi]
[ro.system.product.cpu.abilist32]: [armeabi-v7a,armeabi]
[ro.system.product.cpu.abilist64]: [arm64-v8a]
[ro.vendor.product.cpu.abilist]: [arm64-v8a,armeabi-v7a,armeabi]
[ro.vendor.product.cpu.abilist32]: [armeabi-v7a,armeabi]
[ro.vendor.product.cpu.abilist64]: [arm64-v8a]
```

In this instance, the value to note is `arm64-v8a,armeabi-v7a,armeabi`.

The repository is divided by common ABI list values, so please pick a random JSON file from the relevant folder.

## Where do I put the JSON file?

If copying a file manually (Option 2) there are a couple of places the JSON might need to go.

For the Play Integrity Fix module by [chiteroman](https://github.com/chiteroman/) you should copy the JSON file to:

```text
/data/adb/pif.json
```

And for the [osm0sis](https://github.com/osm0sis) fork (PlayIntegrityFork):

```text
/data/adb/modules/playintegrityfix/custom.pif.json
```

An example command in your terminal emulator might be:

```sh
su -c cp /storage/emulated/0/Download/JSON/arm64-v8a/release-keys/user/Sony_qssi_qssi_13_TKQ1.220807.001_1_user_release-keys.json /data/adb/pif.json
```

Or with ADB in root mode:

```batch
adb push "C:\Users\<User>\Downloads\PIFS\JSON\arm64-v8a\release-keys\user\Sony_qssi_qssi_13_TKQ1.220807.001_1_user_release-keys.json" /data/adb/pif.json
```

## The JSON file I tried doesn't work

This is expected.
The profiles in this repository haven't been tested and, even if they had, it's possible each will only work for a subset of devices.
Keep trying **random** profiles from the relevant folder until one passes the integrity level you want.

Ideally, you'll be able to use your tested profile going forward.
If too many people choose the same one (we're talking thousands, which is less likely if everyone picks at random) it may get blocked for software attestations.
In this case, choose another!
There are plenty to go around.

## `curl` not found or inaccessible

Some users have reported `curl` not working in the root shell.

If you're using Termux as your terminal emulator, you can run the following command (as root):

```sh
/data/data/com.termux/files/usr/bin/curl "https://raw.githubusercontent.com/TheFreeman193/PIFS/main/pickaprint.sh" | sh
```

If your build has `wget`, you can use this command instead (as root):

```sh
wget -O - "https://raw.githubusercontent.com/TheFreeman193/PIFS/main/pickaprint.sh" | sh
```

If you're using Magisk for root, you can try using the included busybox `wget`:

```sh
/data/adb/magisk/busybox wget -O - "https://raw.githubusercontent.com/TheFreeman193/PIFS/main/pickaprint.sh" | sh
```

Or call it directly - it's usually found in one of:

- `/debug_ramdisk/.magisk/busybox/wget`
- `/sbin/.magisk/busybox/wget`

## The script detects the wrong ABI list on my device

If this occurs, you can override the directory the script chooses for fingerprints by setting `$FORCEABI` in the environment.
In your favourite terminal emulator:

```sh
su # Run as root
cd /storage/emulated/0 # Choose the download location where you ran curl
export FORCEABI="armeabi-v7a,armeabi" # Force a different ABI list
cat ./pickaprint.sh | sh # Run the script again
```

If you find fingerprints from another directory work, you can make the `$FORCEABI` variable persistent in Termux.
For example:

```sh
echo 'export FORCEABI="armeabi-v7a,armeabi"' > /data/data/com.termux/files/home/.bashrc
```

## What is the ABI list?

> You can skip the first paragraph if you aren't interested in the technical explanation.

ABIs (application binary interfaces) are low-level interfaces that allow binary processes to interact independent of hardware architecture.
You can think of ABIs as the machine-code counterpart to APIs (application programming interfaces).
ABIs allow Android components and applications to run on a variety of architectures and instruction sets, like x86 and ARM.
List of ABIs supported are stored in a build properties such as `ro.product.cpu.abilist`.

The ABI list is a device property, like the _model_ or _fingerpint_, and appears to affect Play Integrity verdicts.
Using a fingerprint/profile from a device with a different ABI list fails more often that it works in my testing.
This is why the profiles in the repository are divided by supported ABIs - you're much more like to find a profile that works by using a fingerprint from right directory for your device.

## How was this created?

The internet is awash with Android builds and every ROM, whether complete or in source code, contains build properties.
My specialty is in automation (please see the [textbooks](https://leanpub.com/u/devopscollective) I've helped to write - 100% of profits go into scholarships).
My tools, with the aid of the web crawlers from major search engines, have collected a large number of build profiles and extracted the necessary properties to generate compatible JSON files.

I don't intend to release the source code for the collection tools at the moment - many users hammering repository service APIs and individual websites for the same information isn't fair.
I may publish raw build property files at a later date for sources from which I can obtain relevant permissions.

## Further advice

- Build profiles of the `user` type with `release-keys` tags are more likely to work than `userdebug` and `test-keys` or `dev-keys` builds.
- If you lost the `MEETS_BASIC_INTEGRITY` verdict with all the profiles you try, you might be using profiles with the wrong ABI compatibility.
    Check your device's ABI list again or try profiles from another folder.
- Fingerprints/properties with generic values such `generic`, `mainline`, and `Android` are likely to fail and you should use the equivalent _product_ or _vendor_ values instead.
- If you're intermittently passing and failing verdicts with the same profile, it may be that the Play Integrity system is detecting your rooted environment.
    Try using root detectors such as [RootBeerFresh](https://github.com/KimChangYoun/rootbeerFresh/) to check your environment and look at the logs for any Magisk/KernelSU modules you have installed.
- If you're getting timeouts or _too many requests_ errors, the app you're using to check Play Integrity verdicts has hit its API limit.
    Use the checker within Google Play Store instead.

## Play Store Integrity Check

To check Play Integrity verdicts without a third party app, open Play Store and go to settings (click profile icon in top right -> _Settings_).
In the _About_ menu, tap _Play Store version_ repeatedly until you get a notification toast saying "You are now a developer".
Scroll up to the _General_ menu, open it and click _Developer options_.
In this submenu you can click _Check integrity_ to run a Play Integrity check.

The verdicts you need for most apps are `MEETS_BASIC_INTEGRITY` and `MEETS_DEVICE_INTEGRITY`.
