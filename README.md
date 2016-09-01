My DIY Homekit setup in Swift
=============================

This repository is both a showcase of my [HAP](https://github.com/Bouke/HAP) package and implementation of my DIY Homekit setup. It shows how to add Homekit to an internet-connected thermostat (Essent / ICY e-thermostaat).

**How to build:** (as of Xcode 8 beta 6)

Install libsodium (used for Curve25519 and Ed25519):

    brew install libsodium
    brew link libsodium

Install openssl (used for bignum) and symlink the pkg-config files so SwiftPM can discover the correct compiler flags:

    brew install openssl
    ln -s /usr/local/opt/openssl/lib/pkgconfig/*.pc /usr/local/lib/pkgconfig

And then build the project itself:

    swift build

**Usage:**

Run ``swift build`` to compile and ``ICY_USERNAME=xxx ICY_PASSWORD=xxx .build/debug/my-homekit`` to run.

**Linux:**

Currently Linux is not supported due to use of NetService, which is not (yet) available in Swift-Foundation. Patches welcome.

**Dependencies:**

![my-homekit dependencies](http://swiftpm-deps.honza.tech/dependencies/Bouke/my-homekit?format=png)
