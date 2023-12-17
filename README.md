# Play Integrity Fix Props Collection

## What is this?

This repository contains JSON files compatible with the [Play Integrity Fix](https://github.com/chiteroman/PlayIntegrityFix) module by @chiteroman or the @osm0sis [fork](https://github.com/osm0sis/PlayIntegrityFork).

If you don't use a custom ROM and haven't rooted your Android device, you're in the wrong place!

## Why is this needed?

By default, the PIF module and its forks use a single set of build properties (hereafter called a _profile_) for Play Integrity attestation.
With tens of thousands of users using the same profile, the Play Integrity servers inevitably block its use for software attestation.

The best solution in the meantime is for every user to choose a working profile of their own.
Both the original PIF modules and its major fork support this using a JSON file containing real properties from a working device.

## How was this created?

The internet is awash with Android builds and every ROM, whether complete or in source code, contains build properties.
My specialty is in automation (please see the [textbooks](https://leanpub.com/u/devopscollective) I've helped to write - all profits go into scholarships!).
My tools, with the aid of the web crawlers from major search engines, have collected a large number of build profiles and extracted the necessary properties to generate compatible JSON files.

I don't intend to release the source code for the collection tools at the moment - many users hammering repository service APIs and individual websites for the same information isn't fair.
I may publish raw build property files at a later date for sources from which I can obtain relevant permissions.

## How do I choose a JSON file?

**Please choose a random file from the relevant directory. Everyone picking the first or last file will inevitably result in that profile being blocked for software attestation.**

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

For the Play Integrity Fix module you should copy the JSON file to:

```text
/data/adb/pif.json
```

And for the @osm0sis fork:

```text
/data/adb/modules/playintegrityfix/custom.pif.json
```

An example command in your terminal emulator might be:

```sh
su -c cp /storage/emulated/0/Download/RED_HydrogenONE_HydrogenONE_9_PKQ1.190118.001_118_userdebug_release-keys.json /data/adb/pif.json
```

Or with ADB in root mode:

```sh
adb push "C:\\Users\\User\\Downloads\\RED_HydrogenONE_HydrogenONE_9_PKQ1.190118.001_118_userdebug_release-keys.json" /data/adb/pif.json
```

## The JSON file I tried doesn't work

This is expected.
The profiles in this repository haven't been tested and, even if they had, it's possible each will only work for a subset of devices.
Keep trying **random** profiles from the relevant folder until one passes the integrity level you want.

Ideally, you'll be able to use your tested profile going forward.
If too many people choose the same one (we're talking thousands, which is less likely if everyone picks at random) it may get blocked for software attestations.
In this case, choose another!
There are plenty to go around.

## Further advice

- Build profiles of the `user` type with `release-keys` tags are more likely to work than `userdebug` and `test-keys` or `dev-keys` builds.
- If you lost the `MEETS_BASIC_INTEGRITY` verdict with all the profiles you try, you might be using profiles with the wrong ABI compatibility.
    Check your device's ABI list again or try profiles from another folder.
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
