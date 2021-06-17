/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

final class Image: UIImage {
    class func named(_ name: String) -> UIImage? {
        let bundle = Bundle(for: Image.self)

        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
}

extension UIImage {
    static var gradient: UIImage? { return Image.named("Gradient") }
    static var chevron: UIImage? { return Image.named("Chevron") }
    static var about: UIImage? { return Image.named("About") }
    static var star: UIImage? { return Image.named("Star") }
    static var dash: UIImage? { return Image.named("Dash") }
    static var computer: UIImage? { return Image.named("Computer") }
    static var phone: UIImage? { return Image.named("Phone") }
    static var settings: UIImage? { return Image.named("Settings") }
    static var share: UIImage? { return Image.named("Share") }
    static var warning: UIImage? { return Image.named("Warning") }
    static var coronatest: UIImage? { return Image.named("Coronatest") }
    static var coronatestHeader: UIImage? { return Image.named("CoronatestHeader") }
    static var infected: UIImage? { return Image.named("Infected") }
    static var moreInformationStep1: UIImage? { return Image.named("MoreInformation.Step1") }
    static var moreInformationStep1Gray: UIImage? { return Image.named("MoreInformation.Step1-grayscale") }
    static var moreInformationStep2: UIImage? { return Image.named("MoreInformation.Step2") }
    static var moreInformationStep2Gray: UIImage? { return Image.named("MoreInformation.Step2-grayscale") }
    static var moreInformationStep3: UIImage? { return Image.named("MoreInformation.Step3") }
    static var moreInformationStep3Gray: UIImage? { return Image.named("MoreInformation.Step3-grayscale") }
    static var moreInformationStep4: UIImage? { return Image.named("MoreInformation.Step4") }
    static var moreInformationStep4Gray: UIImage? { return Image.named("MoreInformation.Step4-grayscale") }
    static var infectedHeader: UIImage? { return Image.named("InfectedHeader") }
    static var thankYouHeader: UIImage? { return Image.named("ThankYouHeader") }
    static var receivedNotificationHeader: UIImage? { return Image.named("ReceivedNotificationHeader") }
    static var coronaTestHeader: UIImage? { return Image.named("CoronatestHeader") }
    static var statusClouds: UIImage? { return Image.named("StatusClouds") }
    static var statusCloud1: UIImage? { return Image.named("StatusCloud1") }
    static var statusCloud2: UIImage? { return Image.named("StatusCloud2") }
    static var statusScene: UIImage? { return Image.named("StatusScene") }
    static var statusIconOk: UIImage? { return Image.named("StatusIconOk") }
    static var statusIconNotified: UIImage? { return Image.named("StatusIconNotified") }
    static var statusIconInactive: UIImage? { return Image.named("StatusIconInactive") }
    static var statusIconPaused: UIImage? { return Image.named("StatusIconPaused") }
    static var statusInactive: UIImage? { return Image.named("StatusInactive") }
    static var messageHeader: UIImage? { return Image.named("MessageHeader") }
    static var callGGD: UIImage? { return Image.named("CallGGD") }
    static var privacyShield: UIImage? { return Image.named("PrivacyShield") }
    static var bellShield: UIImage? { return Image.named("BellShield") }
    static var bluetoothShield: UIImage? { return Image.named("BluetoothShield") }
    static var lockShield: UIImage? { return Image.named("LockShield") }
    static var pleaseTurnOnBluetooth: UIImage? { return Image.named("Bluetooth") }
    static var pleaseTurnOnNotifications: UIImage? { return Image.named("PleaseTurnOnNotifications") }
    static var shareApp: UIImage? { return Image.named("ShareApp") }
    static var updateApp: UIImage? { return Image.named("UpdateApp") }
    static var info: UIImage? { return Image.named("Info") }
    static var appInformationProtect: UIImage? { return Image.named("AppInfoProtect") }
    static var appInformationNotify: UIImage? { return Image.named("AppInfoNotify") }
    static var appInformationBluetooth: UIImage? { return Image.named("AppInfoBluetooth") }
    static var appInformationExampleCycle: UIImage? { return Image.named("AppInfoCycleExample") }
    static var appInformationExampleTrain: UIImage? { return Image.named("AppInfoTrainExample") }
    static var technicalInformationStep1: UIImage? { return Image.named("TechnicalInfoStep1") }
    static var technicalInformationStep2: UIImage? { return Image.named("TechnicalInfoStep2") }
    static var technicalInformationStep3: UIImage? { return Image.named("TechnicalInfoStep3") }
    static var technicalInformationStep4: UIImage? { return Image.named("TechnicalInfoStep4") }
    static var technicalInformationStep5: UIImage? { return Image.named("TechnicalInfoStep5") }
    static var githubLogo: UIImage? { return Image.named("github") }
    static var aboutAppInformation: UIImage? { return Image.named("AboutAppInformation") }
    static var aboutTechnicalInformation: UIImage? { return Image.named("AboutTechnicalInformation") }
    static var aboutHelpdesk: UIImage? { return Image.named("AboutHelpdesk") }
    static var aboutWebsite: UIImage? { return Image.named("AboutWebsite") }
    static var checkmarkChecked: UIImage? { return Image.named("checkmarkChecked") }
    static var checkmarkUnchecked: UIImage? { return Image.named("checkmarkUnchecked") }
    static var helpNotificationExample: UIImage? { return Image.named("notification-example") }
    static var helpPushNotificationExample: UIImage? { return Image.named("PushNotification-Example") }
    static var onboardingPermissionsHeader: UIImage? { return Image.named("OnboardingPermissionsHeader") }
    static var loadingError: UIImage? { return Image.named("LoadingError") }
    static var onlyTogetherCanWeControlCorona: UIImage? { return Image.named("OnlyTogetherCanWeControlCorona") }
    static var rijkslint: UIImage? { return Image.named("Rijkslint") }
    static var minVWS: UIImage? { return Image.named("MinVWS") }
    static var closeButton: UIImage? { return Image.named("CloseButton") }
    static var settingsIcon: UIImage? { return Image.named("SettingsIcon") }
    static var bluetoothIcon: UIImage? { return Image.named("BluetoothIcon") }
    static var switchIcon: UIImage? { return Image.named("SwitchIcon") }
    static var exposureNotifications: UIImage? { return Image.named("ExposureNotifications") }
    static var notification: UIImage? { return Image.named("Notification") }
    static var settingsPlain: UIImage? { return Image.named("SettingsPlain") }
    static var mobileData: UIImage? { return Image.named("MobileData") }
}

extension UIImage {

    var aspectRatio: CGFloat {
        let width = size.width
        let height = size.height

        guard width > 0, height > 0 else {
            return 1
        }
        return width / height
    }
}
