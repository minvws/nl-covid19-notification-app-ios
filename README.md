G# Covid19 Notification App - iOS

![CI](https://github.com/minvws/nl-covid19-notification-app-ios/workflows/CI/badge.svg)

This repository contains the iOS App of the Proof of Concept for the Dutch exposure notification app. We provide this code in an early stage so that everyone can follow along as we develop the app, and to solicit feedback. Note that due to the early stage in which we are sharing this code, significant portions of the code might still change. We might add or remove features and code as needed, based on validation and user tests that are conducted partially in parallel to the development.

* The iOS app is located in the repository you are currently viewing.
* The Android app can be found here: https://github.com/minvws/nl-covid19-notification-app-android
* The backend can be found here: https://github.com/minvws/nl-covid19-notification-app-backend
* The designs that are used as a basis to develop the apps can be found here: https://github.com/minvws/nl-covid19-notification-app-design
* The architecture that underpins the development can be found here: https://github.com/minvws/nl-covid19-notification-app-coordination

## Development & Contribution process

The core team works on the repository in a private fork (for reasons of compliance with existing processes) and will share its work as often as possible.
If you plan to make non-trivial changes, we recommend to open an issue beforehand where we can discuss your planned changes.
This increases the chance that we might be able to use your contribution (or it avoids doing work if there are reasons why we wouldn't be able to use it).

## Getting Started

Run `make dev` && `make project` to get started. Homebrew (https://brew.sh) is a requirement to install dependencies.

## Continuous Integration & reproducible builds

In order to facilitate CI and reproducible builds (https://github.com/minvws/nl-covid19-notification-app-coordination/issues/6) this codebase can be build using Github Actions.

## OpenSSL

This project relies on OpenSSL to validate the KeySet signatures. OpenSSL binaries (v1.1.1d) are included and can be built using `make build_openssl`. By default the compiled binaries are part of the repo to reduce CI build times. Feel free to compile the binaries yourself.

This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/)

## Validate GAEN signature

Both Apple and Google validate signatures when processing exposure keysets. These so-called GAEN signatures are generated using a private key on our backend. The public key is sent to Google and Apple and for every bundle-identifier, region-identifier, key-version combination they store a public key. 

Examples: 

- nl.rijksoverheid.en.test, region 204, key version v1 -> public key 1
- nl.rijksoverheid.en, region 204, key version v1 -> public key 2

To validate the generated GAEN signatures on mobile please execute the following steps:

- Remove all test entitlements from Debug.entitlements, this leaves two entitlements left: com.apple.developer.exposure-notification and the data protection one
- Compile the app with the `USE_DEVELOPER_MENU` environment variable set
- Once ran, open the development menu, select "Erase Local Storage"
- Validate the correct network environment in the development menu
- Select "Download and Process New KeySets" from the development menu and look at the debugger
- Make sure the number of valid keysets in > 0 (it's logged)
- Make sure you don't see `Error: AddFile, ENErrorDomain:5 'Unable to find Application's Exposure Notification Configuration'`
- In case of success you'll see an ENExposureSummary object in the logs


This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/)

## Disclaimer

Keep in mind that the Apple Exposure Notification API is only accessible by verified health authorities. Other devices trying to access the API using the code in this repository will fail to do so.
