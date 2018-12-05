My DIY Homekit setup in Swift
=============================

This repository is both a showcase of my [HAP](https://github.com/Bouke/HAP) package and implementation of my DIY Homekit setup. It shows how to add Homekit to an internet-connected thermostat (Essent / ICY e-thermostaat).

## Build

### MacOS

Install libsodium (used for Curve25519 and Ed25519):

    brew install libsodium

And then build and run the project itself:

    swift build -c release

### Linux

Install dependencies:

    sudo apt install openssl libssl-dev libsodium-dev libcurl4-openssl-dev

And then build and run the project itself:

    swift build -c release

## Run

    ICY_USERNAME=xxx ICY_PASSWORD= swift run -c release

## Install

To run as a service, create the following file at `/etc/systemd/system/my-home.service`:
```
[Unit]
Description=my-home
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/home/pi/my-home/.build/release/my-home
User=pi
Restart=on-failure
RestartSec=30
Environment=ICY_USERNAME=...
Environment=ICY_PASSWORD=...
WorkingDirectory=/home/pi

[Install]
WantedBy=multi-user.target
```
