# Play Integrity Fix Props Collection

<!-- markdownlint-disable no-inline-html -->

[<img src="https://storage.ko-fi.com/cdn/brandasset/kofi_button_blue.png" alt="Support me on Ko-fi" width="200"/>](https://ko-fi.com/V7V4SGXD9 "Mmm... coffee!")

## What is this?

This repository contains JSON files compatible with the [Play Integrity Fix](https://github.com/chiteroman/PlayIntegrityFix) module by [chiteroman](https://github.com/chiteroman/) or [PlayIntegrityFork](https://github.com/osm0sis/PlayIntegrityFork) made by [osm0sis](https://github.com/osm0sis).

If you don't use a custom ROM and haven't rooted your Android device, you're in the wrong place!

These files aren't tested - they're just a sample of device profiles available online.

## Why is this needed?

By default, the PIF module and some of its forks use a default set of build properties (hereafter called a _profile_) including a build fingerprint for Play Integrity attestation.
With tens of thousands of users using the same profile, the Play Integrity servers inevitably block the associated fingerprint for software attestation.

The best solution in the meantime is for every user to choose a working profile (`pif.json` file) of their own.
Both the original PIF module and its major fork support this using a JSON file containing real properties from a working device.

## How do I choose a JSON file?

### Option 1: Using `pickaprint.sh`

> **NOTE**: It's now recommended to download and run the script as below as this permits the interactive mode where you can mark profiles as working or not working.
> If you pipe the script directly from `curl` or `wget`, the interactive mode is disabled and you'll need to manually mark the current profile using the commands shown when the script exits.

This repository includes `pickaprint.sh` which automates the random selection of a profile with the same ABI compatibility as your device.
It will download the PIFS repository, extract the JSON files, and pick one from the relevant directory at random.

First, enter a root shell and choose your desired download location (it must allow execution):

```sh
su # The script needs to be run as root in order to copy a profile to /data/adb
cd /data/local/tmp # Choose a place where execution is permitted
```

Then, if you're using Magisk for root:

```sh
/data/adb/magisk/busybox wget -O pickaprint.sh "https://raw.githubusercontent.com/TheFreeman193/PIFS/main/pickaprint.sh"
```

Or if you use KernelSU (KSU):

```sh
/data/adb/ksu/bin/busybox wget -O pickaprint.sh "https://raw.githubusercontent.com/TheFreeman193/PIFS/main/pickaprint.sh"
```

Once downloaded, make the script executable and run it:

```sh
chmod 755 ./pickaprint.sh
./pickaprint.sh
```

> **NOTE**: Please don't just run random scripts from the internet, especially as root.
> I strongly urge you to look at the script first and get a basic idea of what it does.

If you haven't run the script before, it will download this repository from GitHub and extract the JSON profiles.

Once a subdirectory called `JSON` exists, the script will search for JSON profiles there instead of downloading the repository all over again.
If the script version is newer than the version in the `JSON` directory, it will download the latest version.

Therefore, to update the collection, run the `wget` command above to get the latest `pickaprint.sh` script, and this will update the collection when next run.

Alternatively, you could download/clone the repository and run the `pickaprint.sh` script directly from the download location.

### Script Arguments

Please [see below](#full-script-usage) for all the arguments you can pass to `pickaprint.sh`.

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
In the example above the directory would be `JSON/arm64-v8a,armeabi-v7a,armeabi`.

The profile filenames are labelled with the _build tags_ and _build type_.
`user` build types are more likely to work than `userdebug` ones, and `release-keys` tagged profiles are more likely to work than `dev-keys` or `test-keys` ones.

Assuming the ABI list you got was `arm64-v8a,armeabi-v7a,armeabi`, you should first look in:

```text
JSON/arm64-v8a,armeabi-v7a,armeabi
```

for a JSON file that ends with:

```text
_user_release-keys.json
```

and copy this to the correct location (see below).

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

An example command in your terminal emulator, for an `arm64-v8a,armeabi-v7a,armeabi` device running the `chiteroman` module might be:

```sh
su -c cp /data/local/tmp/JSON/arm64-v8a,armeabi-v7a,armeabi/Xiaomi_polaris_polaris_9_PKQ1.180729.001_V10.3.3.0.PDGMIXM_user_release-keys.json /data/adb/pif.json
```

Or with ADB in root mode:

```batch
adb push "C:\Users\<User>\Downloads\PIFS\JSON\arm64-v8a,armeabi-v7a,armeabi\Xiaomi_polaris_polaris_9_PKQ1.180729.001_V10.3.3.0.PDGMIXM_user_release-keys.json" /data/adb/pif.json
```

## The JSON file I tried doesn't work

This is expected.
The profiles in this repository haven't been tested and, even if they had, it's possible each will only work for a subset of devices.

Depending on your device, you can expect ~7-24% of the profiles to work at the time of writing, based on my testing.

Keep trying **random** profiles from the relevant folder until one passes the integrity level you want.

Some newer `arm64-v8a`-only devices like the Pixel 7 don't appear to work with `arm64-v8a` profiles when using beta builds of Android 14.
In these cases, try using `arm64-v8a,armeabi-v7a,armeabi` profiles (see the [wrong ABI list](#the-script-detects-the-wrong-abi-list-on-my-device) section.)

Ideally, you'll be able to use your tested profile going forward.
If too many people choose the same one (we're talking thousands, which is less likely if everyone picks at random) it may get blocked for software attestations.
In this case, choose another!
There are plenty to go around.

## `curl` or `wget` not found or inaccessible

There may be edge cases where you're unable to download the script using the methods described above.

If you're using Termux as your terminal emulator, you can run the following command (as root):

```sh
/data/data/com.termux/files/usr/bin/curl -o pickaprint.sh "https://raw.githubusercontent.com/TheFreeman193/PIFS/main/pickaprint.sh"
```

Then proceed as discussed [above](#option-1-using-pickaprintsh).

## The script detects the wrong ABI list on my device

If this occurs, you can override the directory the script chooses for fingerprints by setting `$FORCEABI` in the environment.
In your favourite terminal emulator:

```sh
su # Run as root
cd /data/local/tmp # Choose the location where you downloaded the script
export FORCEABI="arm64-v8a,armeabi-v7a,armeabi" # Force a different ABI list
./pickaprint.sh # Run the script again
```

If you find fingerprints from another directory work, you can make the `$FORCEABI` variable persistent in Termux.
For example:

```sh
echo 'export FORCEABI="arm64-v8a,armeabi-v7a,armeabi"' > /data/data/com.termux/files/home/.bashrc
```

This forces the script to always use `arm64-v8a,armeabi-v7a,armeabi` profiles.

To remove this override immediately, you can use:

```sh
unset FORCEABI
```

If added to your emulator's `bashrc` file, you'll need to remove that line.
For Termux, this file can be found at:

```text
/data/data/com.termux/files/home/.bashrc
```

## What is the ABI list?

> You can skip the first paragraph if you aren't interested in the technical explanation.

ABIs (application binary interfaces) are low-level interfaces that allow binary processes to interact independent of hardware architecture.
You can think of ABIs as the machine-code counterpart to APIs (application programming interfaces).
ABIs allow Android components and applications to run on a variety of architectures and instruction sets, like x86 and ARM.
Lists of supported ABIs are stored in build properties such as `ro.product.cpu.abilist`.

The ABI list is a device property, like the _model_ or _fingerpint_, and appears to affect Play Integrity verdicts.
Using a fingerprint/profile from a device with a different ABI list fails more often that it works in my testing.
This is why the profiles in the repository are divided by supported ABIs - you're much more like to find a profile that works by using a fingerprint from right directory for your device.

## Updates

The `JSON` directory now includes a `VERSION` file which documents the collection version.
The `pickaprint.sh` script checks for this and re-downloads the collection if an updated one is available.

If you don't want to receive updates, set the `PIFSNOUPDATE` environment variable:

```sh
export PIFSNOUPDATE=1 # Disable updates

unset PIFSNOUPDATE # Re-enable updates
```

Make this persistent by adding such a line to the `bashrc` script of your favourite emulator:
For example:

```sh
echo 'export PIFSNOUPDATE=1' > /data/data/com.termux/files/home/.bashrc
```

## Full Script Usage

```text
Usage: ./pickaprint.sh [-x] [-i] [-c] [-s] [-h|?]


  -x  Add existing pif.json/custom.pif.json profiles to exclusions and pick a print
  -i  Add existing pif.json/custom.pif.json profiles to confirmed and exit
  -c  Use only confirmed profiles from '/data/adb/pifs/confirmed'
  -s  Add additional 'SDK_INT'/'*.build.version.sdk' props to profile
  -h  Display this help message
```

### Excluding Profiles

When you select _no_ for a profile that doesn't pass integrity, the script adds it automatically to a list of exclusions, and moves it to `/data/adb/pifs/failed/`.
The script will not attempt to use this profile again.

To exclude the existing profile in the `pif.json` or `custom.pif.json`, run the script with the `-x` argument:

```sh
./pickaprint.sh -x
```

The exclusions list is stored at `/data/adb/failedpifs.lst`.
This list ensures you can update the collection without having to try all your previously failed profiles.

If a profile exists in the relevant module directory when you first run the script, and you don't pass the `-x` argument, it'll be backed up to `/data/adb/pifs/backup/`

### Using Only Tested Profiles

When you select _yes_ for a profile that passes integrity, the script copies it to `/data/adb/pifs/confirmed/`.

To use **only** profiles from this directory, run the script with the `-c` argument:

```sh
./pickaprint.sh -c
```

You can copy your own working profiles to the `confirmed` directory and the script will use them when run with `-c`.

### Marking the Current Profile as Confirmed

You can mark the current profile (`pif.json` or `custom.pif.json`) as confirmed working using the `-i` argument:

```sh
./pickaprint.sh -i
```

The script will exit immediately after adding this profile to `/data/adb/pifs/confirmed/`.

### Including `SDK_INT` and `*.build.version.sdk` Properties

Some devices need to spoof these additional values to pass `DEVICE` integrity.
If your working profile started failing with the v3 script, you can try using the `-s` argument:

```sh
./pickaprint.sh -s
```

The script will dynamically add the additional properties when copying profiles.

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
- If you make too many integrity requests, even in Play Store, you may see a `Retry with an exponential backoff` response.
    In this case, stop testing for a couple of minutes and retry at a slower rate.

## Play Store Integrity Check

To check Play Integrity verdicts without a third party app, open Play Store and go to settings (click profile icon in top right -> _Settings_).
In the _About_ menu, tap _Play Store version_ repeatedly until you get a notification toast saying "You are now a developer".
Scroll up to the _General_ menu, open it and click _Developer options_.
In this submenu you can click _Check integrity_ to run a Play Integrity check.

The verdicts you need for most apps are `MEETS_BASIC_INTEGRITY` and `MEETS_DEVICE_INTEGRITY`.
