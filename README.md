# COVID-19 Notification App - iOS

![CI](https://github.com/minvws/nl-covid19-notification-app-ios/workflows/CI/badge.svg)

This repository contains the native iOS implementation of the Dutch COVID-19 Notification App CoronaMelder. 

* The iOS app is located in the repository you are currently viewing.
* The Android app can be found here: https://github.com/minvws/nl-covid19-notification-app-android
* The backend can be found here: https://github.com/minvws/nl-covid19-notification-app-backend
* The designs that are used as a basis to develop the apps can be found here: https://github.com/minvws/nl-covid19-notification-app-design
* The architecture that underpins the development can be found here: https://github.com/minvws/nl-covid19-notification-app-coordination


## Table of Contents
1. [About the app](#about)
1.1 [App Requirements](#requirements)
1.2 [Feature overview](#featureoverview)
2. [Development & Contribution process](#development)
2.1 [Build Requirements](#developmentrequirements)
2.2 [Getting started](#gettingstarted)
2.3 [Continuous Integration & reproducible builds](#ci)
2.4 [OpenSSL](#openssl)
2.5 [Validate GAEN signature](#gaensignature)
2.6 [SSL Hash Generation](#hashgeneration)
2.7 [GAEN API Disclaimer](#gaendisclaimer)
3. [Architecture (external link)](ARCHITECTURE.md)

<a name="about"></a>
## 1. About the app
CoronaMelder is a COVID-19 exposure notification app. Its main use is to notify users of the app when they previously were in (close) contact with a person who later tested positive for the coronavirus. The app does this by using Apple and Google's GAEN framework that uses Bluetooth Low Energy to monitor proximity to other people who have CoronaMelder or any of the other GAEN-based apps installed on their iOS or Android phone.

<a name="requirements"></a>
### 1.1 App Requirements
The app can run on devices that meet the following requirements.

- Operating System: iOS 12.5+
- Internet connection (either Wifi or Mobile Data)
- Bluetooth

**Note:** Although the app can be _installed_ on iOS 12.5 and higher, iOS 13 to iOS 13.6 don't support the GAEN features that the app uses. On these iOS versions, CoronaMelder will permanently show a splash screen asking users to update their device to iOS 14.

<a name="featureoverview"></a>
### 1.2 Feature Overview
This is a general overview of the features that are available in the app:

- **Onboarding**. When the app starts or the first time, the user is informed of the functionality of the app and is asked to give permission for local notifications and the use of the GAEN framework.
- **Share GGD Key**. If you have tested positive for coronavirus, you can share you unique identifiers publicly to make sure people who came into contact with you during the infectious period are alerted. (This action can only be performed when the user is called by the GGD).
- **Pausing**. The user has the option to pause the contact tracing framework for a set number of hours. This is useful when you are in an environment where other measures have been taken to protect people from the virus or in situations where you are aware that you are interacting with a large number of potentially infected individuals (like in Coronavirus testlocations) and you don't want to receive notifications about this in the future.
- **Q&A Section**. In-app information about the functionality of the app, how your privacy is protected and how the app works in detail.
- **Requesting a Coronatest**. Information on how to request a Coronatest with links to related websites or phonenumbers. Note that you can not directly request a test within the app itself.
- **Invite people to use the app**. Allows the user to share a link to [coronamelder.nl](coronamelder.nl) to their friends & family using the native iOS share sheet.

Other functions of the app that are automatically performed and are not available through the UI of the app:

- **Contact Tracing** using the GAEN framework. The app regularly downloads published keys from a public API and checks if the user ever came into contact with the device from which these infectious keys originated. This work is performed in regularly scheduled background tasks.
- **Decoy Traffic Generation**. Since the "Share GGD Key" functionality of the app sends data to the API, any network traffic coming from the app could be construed as a sign that the user was infected. Because this presents a potential breach of privacy, the app regularly schedules similar (decoy) calls to the API to mask this traffic.


<a name="development"></a>
## 2. Development & Contribution process
The development team works on the repository in a private fork (for reasons of compliance with existing processes) and shares its work as often as possible.
If you plan to make non-trivial changes, we recommend to open an issue beforehand where we can discuss your planned changes.
This increases the chance that we might be able to use your contribution (or it avoids doing work if there are reasons why we wouldn't be able to use it).

<a name="buildrequirements"></a>
### 2.1 Build Requirements

To build and develop the app you need:

- [Xcode 12.4](https://download.developer.apple.com/Developer_Tools/Xcode_12.4/Xcode_12.4.xip)
- Xcode Command Line tools (Specifically "Make").
- [Homebrew](https://brew.sh/)

<a name="gettingstarted"></a>
### 2.2 Getting Started

The project uses a Makefile in the root folder of the repository to perform basic actions needed for the development of the app.

- `make dev` to install all required libraries and components to develop the app
- `make project` to generate the .xcodeproj file for the app. This uses `xcodegen` and the project.yml file in the root folder of the repository.

Other commands that are available and might  be useful during the development process:

- `make clean_snapshots` to delete all recorded snapshot test reference file in the repository. This is handy if you want to re-record all snapshots after a big change or after changing the Simulator / OS version you want the snapshots to be recorded on.
- `make push_notification` send a mock push notification to the app running in the simulator. The payload for this notification can be found in `tools/push/payload.apns`

<a name="ci"></a>
### 2.3 Continuous Integration & reproducible builds

In order to facilitate CI and reproducible builds (https://github.com/minvws/nl-covid19-notification-app-coordination/issues/6) this codebase can be build using Github Actions.

<a name="openssl"></a>
### 2.4 OpenSSL

This project relies on OpenSSL to validate the KeySet signatures. OpenSSL binaries (v1.1.1d) are included and can be built using `make build_openssl`. By default the compiled binaries are part of the repo to reduce CI build times. Feel free to compile the binaries yourself.

This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/)

<a name="gaensignature"></a>
### 2.5 Validate GAEN signature

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

<a name="hashgeneration"></a>
#### 2.6 SSL Hash Generation

```
let certificate = """
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
"""
let cert = certificate
    .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
    .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
    .replacingOccurrences(of: "\n", with: "")
let certData = Data(base64Encoded: cert)!

guard let secCert = SecCertificateCreateWithData(nil, certData as CFData) else {
    fatalError()
}

print(Certificate(certificate: secCert).signature!)
```

<a name="gaendisclaimer"></a>
### 2.7 GAEN API Disclaimer


Keep in mind that the Apple Exposure Notification API is only accessible by verified health authorities. Other devices trying to access the API using the code in this repository will fail to do so.
