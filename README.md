# CoronaMelder - COVID-19 Notification App for iOS
 
![CI](https://github.com/minvws/nl-covid19-notification-app-ios/workflows/CI/badge.svg)

This repository contains the native iOS implementation of the Dutch COVID-19 Notification App CoronaMelder. 

* The iOS app is located in the repository you are currently viewing.
* The Android app can be found here: [https://github.com/minvws/nl-covid19-notification-app-android]()
* The backend can be found here: [https://github.com/minvws/nl-covid19-notification-app-backend]()
* The designs that are used as a basis to develop the apps can be found here: [https://github.com/minvws/nl-covid19-notification-app-design]()
* The architecture that underpins the development can be found here: [https://github.com/minvws/nl-covid19-notification-app-coordination]()
* the architecture of the app itself is described here: [Architecture](ARCHITECTURE.md)

## Table of Contents
1. [About the app](#about)
1.1 [App Requirements](#requirements)
1.2 [Feature overview](#featureoverview)
1.3 [Dependencies](#dependencies)
1.4 [Deactivation](#deactivation)
2. [Development & Contribution process](#development)
2.1 [Build Requirements](#developmentrequirements)
2.2 [Getting started](#gettingstarted)
2.3 [Continuous Integration & reproducible builds](#ci)
2.4 [Validate GAEN signature](#gaensignature)
2.5 [SSL Hash Generation](#hashgeneration)
2.6 [GAEN API Disclaimer](#gaendisclaimer)
2.7 [Developer Menu](#developermenu)
3. [Where to begin development](#wheretobegin)
4. [Background Task](#backgroundtask)
5. [Theming, Strings, Fonts and Images](#theming)
5.1 [Translations](#translations)
5.1.1 [Uploading iOS translations to OneSky](#uploadtranslations)
5.1.2 [Downloading and importing iOS translations from OneSky](#downloadtranslations)
6. [Release Procedure](#releaseprocedure)

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

<a name="dependencies"></a>
### 1.3 Dependencies

The app uses a number of external dependencies. To make sure we always use the correct version of these dependencies and to mitigate the risk of contaminating the codebase with unwanted code, the source code of these dependencies can be found within the repository in the `vendor/` folder.

Here is an overview of what dependencies are used and why.

<a name="deactivation"></a>
### 1.4 Deactivation
Currently the app has been deactivated, ceasing all server communications, revert [1cef3786](1cef3786e2f1e8caf34da7c7be142eb8f62fe469) to enable communication with the CDN again.

- **CocoaLumberjack**
Logging framework. When the app is build with debugging enabled, the app logs information to a local logfile that can be exported via the developer menu (sidebar menu that can be accessed by swiping to the left with 2 fingers on the screen). When the app is built for release, this logging is disabled. This means that builds that are published to the App Store do **not** log any information.

- **Lottie**
Lottie is used to display JSON-based animations within the app. The animation files can be found in `ENCore/Resources/Animations`

- **Mockolo**
Mockolo is an application that can generate mock classes based on protocols. These mock classes are used in our test suites to inject as dependencies in classes that are tested.

- **OpenSSL-for-iPhone**
This project relies on OpenSSL to validate the KeySet signatures. OpenSSL binaries (v1.1.1d) are included and can be built using `make build_openssl`. By default the compiled binaries are part of the repo to reduce CI build times. Feel free to compile the binaries yourself. This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/)

- **Reachability** ([https://github.com/ashleymills/Reachability.swift]())
Helper library to determine network connection status and reachability of the API.

- **RxSwift** ([https://github.com/ReactiveX/RxSwift]())
Reactive Programming framework. RxSwift is used throughout the app to monitor the state of the App, the GAEN framework, the network etc. and update the UI accordingly.

- **Snapkit** ([https://github.com/SnapKit/SnapKit]())
SnapKit simplifies autolayout code within the app by providing a Domain Specific Language to describe the layout of the interface.
- **Swift-snapshot-testing** ([https://github.com/pointfreeco/swift-snapshot-testing]())
Used to snapshot test UI components of the app. Snapshot tests are unit tests that generate an image or textual description of the UI and then compare the UI against those references in later test runs to catch (unexpected) visual changes to the interface.
- **SwiftFormat** ([https://github.com/nicklockwood/SwiftFormat]())
Command Line tool to standardize code formatting. This can run as a pre-commit githook that can be installed using `make install_dev_deps`.
- **XcodeGen** ([https://github.com/yonaskolb/XcodeGen]())
Command Line tool to generate an Xcode projectfile based on a project.yml description file. The .xcodeproj file that is generated by this tool is not checked into the git repository but has to be created when checking out the code by running `make project`.
- **ZipFoundation** ([https://github.com/weichsel/ZIPFoundation]())
Zip / unzip library. Used to unpack all compressed content we receive from the API.


<a name="development"></a>
## 2. Development & Contribution process
The development team works on the repository in a private fork (for reasons of compliance with existing processes) and shares its work as often as possible.
If you plan to make non-trivial changes, we recommend to open an issue beforehand where we can discuss your planned changes.
This increases the chance that we might be able to use your contribution (or it avoids doing work if there are reasons why we wouldn't be able to use it).

<a name="buildrequirements"></a>
### 2.1 Build Requirements

To build and develop the app you need:

- Xcode 13
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

In order to facilitate CI and reproducible builds (https://github.com/minvws/nl-covid19-notification-app-coordination/issues/6) this codebase can be built using Github Actions.


<a name="gaensignature"></a>
### 2.4 Validate GAEN signature

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
#### 2.5 SSL Hash Generation

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
### 2.6 GAEN API Disclaimer
Keep in mind that the Apple Exposure Notification API is only accessible by verified health authorities. Other devices trying to access the API using the code in this repository will fail to do so.

<a name="developermenu"></a>
### 2.7 Developer menu
To aid in development of the app, a special hidden side menu was built that can be used to check or change the state of the app. This developer menu is only included in debug or test builds of the app and can be accessed on any screen bij swiping to the left with 2 fingers. Some of the features that can be found in this menu are:

- Showing screens of the app that can normally only be accessed in specific situations. Like the onboarding screens, the OS update screen or the App Update screen.
- Changing the state of the GAEN framework. Enabling / disabling it, mimicking a disabled bluetooth connection.
- Simulating a possible exposure on a specific date.
- Removing / fetching exposure key sets.
- Erasing all locally stored data.
- Sharing the log files of the app.

<a name="wheretobegin"></a>
## 3. Where to begin development
Even though the architecture of the app is quite straight forward, it can still be hard to grasp the complexity as a new developer. Here are some helpful points in the codebase to start from.

- **MainViewController** is a container that contains 2 other viewcontrollers (**StatusViewController** and **MoreInformationViewController**) that together represent the main screen of the app. It shows the status of the user / framework (exposed or not exposed) and a menu that gives access to all other features of the app.
- **RootRouter** is the location of the startup sequence of the app. It determines which screen is shown when the app starts (onboarding screens, the main screen or something else) 
- **BackgroundController** handles the scheduling and execution of the background task that is the "heartbeat" of the app. It keeps the app up-to-date and performs exposure checks.

<a name="backgroundtask"></a>
## 4. Background Task
One of the most important aspects of the app is a regularly scheduled background task that wakes up the app. Since the scheduling of background tasks is normally not guaranteed by iOS, CoronaMelder (like any other GAEN app) is given a __special entitlement__ by Apple (based on the Bundle ID) that allows this scheduling to be more reliable. The task is currently scheduled to run every hour. However, not all work in this task will be performed during each run since they might depend on content from the backend that is updated in other intervals.

This is an overview of the work that is performed by the background task. The scheduling and execution of this work can all be found in the `BackgroundController` class:

- `removePreviousExposureDateIfNeeded`. This cleans up any stored exposure date after 14 days. The exposure date is stored during this period to make it possible for the app to determine if an exposure was detected before. 
- `activateExposureController`. This prepares the GAEN framework for some of the work following work.
- `updateStatusStream`. This makes sure the app is aware of the status of the GAEN framework, including things like the state of Bluetooth or Internet connection on the device.
- `fetchAndProcessKeysets`. This downloads the latest keyset batches from the API, submits them to the GAEN framework and checks if the keysets lead to a possible exposure.
- `processPendingUploads`. This uploads the users GGD key if a previous attempt by the user failed to do so (for instance due to network issues)
- `sendInactiveFrameworkNotificationIfNeeded`. If the app is unable to download or process keysets for 24 hours, the app sends a local notification to the user that indicates that CoronaMelder is not functioning correctly.
- `sendNotificationIfAppShouldUpdate`. In some situations, the development team might want to force users to update to the latest version of the app. For instance if there is a bug that prevents the app from functioning correctly. In that case, the __appconfig__ file coming from the API will contain a "iOSMinimumVersion" field. This task checks that minimum version and sends a local notification to the user indicating that they should update the app.
- `updateTreatmentPerspective`. This updates the content we show to users if a possible exposure was detected. The content is retrieved from the API and should always be in line with the latest government guidelines.
- `sendExposureReminderNotificationIfNeeded`. If we previously detected an exposure, this task periodically reminds the user of this exposure using a local notification.
- `processDecoyRegisterAndStopKeys`. This triggers decoy calls to the API that are intended to obfuscate the network traffic. This obfuscation makes sure that it is not possible to determine if somebody has shared a GGD-key (and was infected) based on the network traffic of the app.

<a name="theming"></a>
## 5. Theming, Strings, Fonts and Images
To ensure a clean look & feel of the app, we have standardised the use of UI components such as text, fonts and images.

- __Strings__ are all stored in (translated) .strings files and are only accessed through static properties and functions in `Localization.swift`. This makes sure we don't make errors in the string's name and allows us to also fallback to a specific base language if the user's system language is not available. See more about the translation of these strings in [Managing Translations](#translations).
- Colors and Fonts can be accessed through a __Theme__ object that is propagated throughout the app.
- __Fonts__ are standardised in ENFoundation/Fonts.swift. The name of the fonts we use follows iOS's semantic font naming conventions.
- __Colors__ are stored in ENFoundation/Resources/Colors.xcassets and can be accessed through the __Theme__ object. The color assets file contains both Light and Dark appearances because we support Dark mode within the application.
- __Images__ are stored in ENCore/Resources/Assets.xcassets. These can be accessed by static properties on UIImage itself (like `UIImage.chevron`). Most images have Light and Dark appearances set to support Dark mode within the app.

<a name="translations"></a>
### 5.1 Managing Translations
The content of the app is translated into 10 different languages. These translations are done via [OneSky](https://www.oneskyapp.com/). 

<a name="uploadtranslations"></a>
#### 5.1.1 Uploading iOS translations to OneSky
- The App contains 2 Resource folders:
    - Sources/EN/Resources
    - Sources/ENCore/Resources
- Open OneSky and go to the iOS Project
- Click the + icon next to **Files** on the left side of the screen
- Drag Sources/ENCore/Resources/nl.lproj/Localizable.strings to OneSky
- Rename Sources/EN/Resources/nl.lproj/Localizable.strings to Main.strings
- Drag Sources/EN/Resources/nl.lproj/Main.strings to OneSky
- Always select the **deprecate** option in OneSky

When updating existing translations by uploading files, make sure the Dutch language is not finalised, otherwise updates won't "overwrite" existing translations. Translations are set to crowdsource mode which means that everyone with access to the url can sign up and add translations for non-finalised strings, so for that reason finalising the translations is advisable too.

<a name="download"></a>
#### 5.1.2 Downloading and importing iOS translations from OneSky
- Check out the master branch in git
- Go to OneSky -> Translation Overview and click **Download Translation** on the top right
- Select all languages and all files
- Click **Export**
- Unzip the downloaded file
- Open a terminal and go to <Source Root>/tools/scripts
- Type "sh import-onesky.sh /absolute/path/of/extracted/onesky/folder". This will import the files and copy them to the correct location in the project

<a name="releaseprocedure"></a>
## 6. Release Procedure
The following steps need to be taken to create a version of CoronaMelder and release it to the iOS App Store:

- Update the version number of the app in the `project.yml`. The version number is set by the `CFBundleShortVersionString` property in that file.
- When the `master` branch is built, various build versions are automatically sent to Firebase App Distribution to make it easier to test the release.
- Once the team is satisfied with the quality of the builds on Firebase App Distribution, the build can be sent to TestFlight using the internal release system (Azure DevOps)
- Once the app hits TestFlight, we perform a manual regression test on the build to make sure the app performs as normal in this production-like environment.
- If the team determines the app is ready for release, we manually submit the app for App Store Review via [App Store Connect](https://appstoreconnect.apple.com/). We typically choose a manual release action instead of automatically releasing it on App Store approval to make sure we release the app on a day when we have enough personel to monitor the release.

**After release**
After the app is released to the App Store we perform some actions to tag the release, make it public and verify the integrity of the released code:

- We tag the release in our internal Git repository with a name matching the release version. for example `2.4.2`.
- We push the code from our internal Git repository to the GitHub repository to make it public.
- We publish the created tag to GitHub too.
- We communicate the tag that was pushed to GitHub to an Escrow party (via the internal Product Owner) that can confirm that the code of the released app matches the code that was tagged. This ensures that no malicious changes were made to the code during the release process.
