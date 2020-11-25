/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

public final class Localization {

    enum SupportedLanguageIdentifier: String {
        case ar
        case bg
        case de
        case es
        case pl
        case ro
        case tr
        case nl
        case en
        case fr
    }

    /// Get the Localized string for the current bundle.
    /// If the key has not been localized this will fallback to the Base project strings
    public static func string(for key: String, comment: String = "", _ arguments: [CVarArg] = []) -> String {
        if let override = localization() {
            guard
                let path = Bundle(for: Localization.self).path(forResource: override, ofType: "lproj"),
                let bundle = Bundle(path: path) else {
                let value = NSLocalizedString(key, bundle: Bundle(for: Localization.self), comment: comment)
                return (arguments.count > 0) ? String(format: value, arguments: arguments) : value
            }
            let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
            if override != "Base" {
                print(override)
            }
            return (arguments.count > 0) ? String(format: localizedString, arguments: arguments) : localizedString
        }

        let value = NSLocalizedString(key, bundle: Bundle(for: Localization.self), comment: comment)
        guard value == key else {
            return (arguments.count > 0) ? String(format: value, arguments: arguments) : value
        }
        guard
            let path = Bundle(for: Localization.self).path(forResource: "Base", ofType: "lproj"),
            let bundle = Bundle(path: path) else {
            return (arguments.count > 0) ? String(format: value, arguments: arguments) : value
        }
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
        return (arguments.count > 0) ? String(format: localizedString, arguments: arguments) : localizedString
    }

    public static func attributedString(for key: String, comment: String = "", _ arguments: [CVarArg] = []) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: string(for: key, arguments))
    }

    public static func attributedStrings(for key: String, comment: String = "", _ arguments: [CVarArg] = []) -> [NSMutableAttributedString] {
        let value = string(for: key, arguments)
        let paragraph = "\n\n"
        let strings = value.components(separatedBy: paragraph)

        return strings.enumerated().map { (index, element) -> NSMutableAttributedString in
            let value = index < strings.count - 1 ? element + "\n" : element
            return NSMutableAttributedString(string: value)
        }
    }

    public static var isRTL: Bool {
        #if DEBUG
            if let overriddenIsRTL = LocalizationOverrides.overriddenIsRTL {
                return overriddenIsRTL
            }
        #endif

        return UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft
    }

    static var isUsingDutchLanguage: Bool {
        Locale.current.languageCode?.lowercased() == "nl"
    }
}

extension String {

    // MARK: - Helpdesk Phone Number

    static var helpDeskPhoneNumber = "0800-1280"
    static var coronaTestPhoneNumber = "0800-1202"
    static var coronaTestExposedPhoneNumber = "0800-2035" // Only shown/used when we know the user was exposed to an affected person
    static var coronaTestWebUrl = "https://coronatest.nl"
    static var coronaTestWebUrlInternational = "https://coronatest.nl/en"
    static var interoperabilityLink = "https://coronamelder.nl/%@/operabiliteit"
    static var interoperabilityFAQLink = "https://coronamelder.nl/%@/faq/13-gebruik-app-uit-ander-land/"

    static func phoneNumberLink(from phoneNumber: String) -> String {
        return "tel://\(phoneNumber.replacingOccurrences(of: "-", with: ""))"
    }

    // MARK: - Share App

    static var shareAppUrl = "https://coronamelder.nl/app"
    static var shareAppTitle: String { return Localization.string(for: "shareAppTitle") }

    // MARK: - General Texts

    static var ok: String { return Localization.string(for: "ok") }
    static var yes: String { return Localization.string(for: "yes") }
    static var no: String { return Localization.string(for: "no") }
    static var warning: String { return Localization.string(for: "warning") }
    static var back: String { return Localization.string(for: "back") }
    static var cancel: String { return Localization.string(for: "cancel") }
    static var example: String { return Localization.string(for: "example") }
    static var close: String { return Localization.string(for: "close") }
    static var errorTitle: String { return Localization.string(for: "error.title") }
    static var learnMore: String { return Localization.string(for: "learnMore") }

    // MARK: - Update App

    static var updateAppErrorMessage: String { return Localization.string(for: "updateApp.error.message") }
    static var updateAppTitle: String { return Localization.string(for: "updateApp.title") }

    static var updateAppContent: String { return Localization.string(for: "updateApp.content") }
    static var updateAppButton: String { return Localization.string(for: "updateApp.button") }

    static var endOfLifeTitle: String { return Localization.string(for: "endOfLife.title") }
    static var endOfLifeDescription: String { return Localization.string(for: "endOfLife.description") }

    // MARK: - Onboarding Steps

    static var onboardingPermissionsTitle: String { return Localization.string(for: "onboarding.permissions.title") }
    static var onboardingPermissionsDescription: String { return Localization.string(for: "onboarding.permissions.description") }
    static var onboardingPermissionsDescriptionList1: String { return Localization.string(for: "onboarding.permissions.description.list1") }
    static var onboardingPermissionsDescriptionList2: String { return Localization.string(for: "onboarding.permissions.description.list2") }
    static var onboardingPermissionsSecondaryButton: String { return Localization.string(for: "onboarding.permissions.secondary_button") }
    static var onboardingPermissionsPrimaryButton: String { return Localization.string(for: "onboarding.permissions.primary_button") }

    static var step1Title: String { return Localization.string(for: "step1Title") }
    static var step1Content: String { return Localization.string(for: "step1Content") }

    static var step2Title: String { return Localization.string(for: "step2Title") }
    static var step2Content: String { return Localization.string(for: "step2Content") }

    static var step3Title: String { return Localization.string(for: "step3Title") }
    static var step3Content: String { return Localization.string(for: "step3Content") }

    static var step4Title: String { return Localization.string(for: "step4Title") }
    static var step4Content: String { return Localization.string(for: "step4Content") }

    static var step5Title: String { return Localization.string(for: "step5Title") }
    static var step5Content: String { return Localization.string(for: "step5Content") }

    // MARK: - Onboarding

    static var nextButtonTitle: String { return Localization.string(for: "nextButtonTitle") }

    // MARK: - Consent Steps

    static var consentSkipEnTitle: String { return Localization.string(for: "consentSkipEnTitle") }
    static var consentSkipEnMessage: String { return Localization.string(for: "consentSkipEnMessage") }
    static var consentSkipEnAcceptButton: String { return Localization.string(for: "consentSkipEnAcceptButton") }
    static var consentSkipEnDeclineButton: String { return Localization.string(for: "consentSkipEnDeclineButton") }

    static var consentStep1Title: String { return Localization.string(for: "consentStep1Title") }
    static var consentStep1Summary1: String { return Localization.string(for: "consentStep1Summary1") }
    static var consentStep1Summary2: String { return Localization.string(for: "consentStep1Summary2") }
    static var consentStep1Summary3: String { return Localization.string(for: "consentStep1Summary3") }
    static var consentStep1PrimaryButton: String { return Localization.string(for: "consentStep1PrimaryButton") }
    static var consentStep1SecondaryButton: String { return Localization.string(for: "consentStep1SecondaryButton") }

    static var consentStep2Title: String { return Localization.string(for: "consentStep2Title") }
    static var consentStep2Content: String { return Localization.string(for: "consentStep2Content") }
    static var consentStep2PrimaryButton: String { return Localization.string(for: "consentStep2PrimaryButton") }
    static var consentStep2SecondaryButton: String { return Localization.string(for: "consentStep2SecondaryButton") }

    static var consentStep3Title: String { return Localization.string(for: "consentStep3Title") }
    static var consentStep3Content: String { return Localization.string(for: "consentStep3Content") }
    static var consentStep3PrimaryButton: String { return Localization.string(for: "consentStep3PrimaryButton") }
    static var consentStep3SecondaryButton: String { return Localization.string(for: "consentStep3SecondaryButton") }

    static var consentStep4Title: String { return Localization.string(for: "consentStep4Title") }
    static var consentStep4Content: String { return Localization.string(for: "consentStep4Content") }
    static var consentStep4PrimaryButton: String { return Localization.string(for: "consentStep4PrimaryButton") }
    static var consentStep4SecondaryButton: String { return Localization.string(for: "consentStep4SecondaryButton") }

    // MARK: - Bluetooth

    static var enableBluetoothTitle: String { return Localization.string(for: "enableBluetoothTitle") }

    static var enableBluetoothSettingIndexRow1: String { return Localization.string(for: "enableBluetoothSettingIndexRow1") }
    static var enableBluetoothSettingTitleRow1: String { return Localization.string(for: "enableBluetoothSettingTitleRow1") }
    static var enableBluetoothSettingTitleSettingRow1: String { return Localization.string(for: "enableBluetoothSettingTitleSettingRow1") }

    static var enableBluetoothSettingIndexRow2: String { return Localization.string(for: "enableBluetoothSettingIndexRow2") }
    static var enableBluetoothSettingTitleRow2: String { return Localization.string(for: "enableBluetoothSettingTitleRow2") }
    static var enableBluetoothSettingTitleSettingRow2: String { return Localization.string(for: "enableBluetoothSettingTitleSettingRow2") }

    static var enableBluetoothSettingIndexRow3: String { return Localization.string(for: "enableBluetoothSettingIndexRow3") }
    static var enableBluetoothSettingTitleRow3: String { return Localization.string(for: "enableBluetoothSettingTitleRow3") }
    static var enableBluetoothSettingTitleSettingRow3: String { return Localization.string(for: "enableBluetoothSettingTitleSettingRow3") }

    // MARK: - Consent

    static var skipStep: String { return Localization.string(for: "skipStep") }

    // MARK: - Help

    static var helpTitle: String { return Localization.string(for: "helpTitle") }
    static var helpSubtitle: String { return Localization.string(for: "helpSubtitle") }
    static var helpAcceptButtonTitle: String { return Localization.string(for: "helpAcceptButtonTitle") }
    static var helpContent: String { return Localization.string(for: "helpContent") }
    static var helpAlsoRead: String { return Localization.string(for: "helpAlsoRead") }

    static var helpFaqReasonTitle: String { return Localization.string(for: "help.faq.reason.title") }
    static var helpFaqReasonDescription: String { return Localization.string(for: "help.faq.reason.description") }
    static var helpFaqLocationTitle: String { return Localization.string(for: "help.faq.location.title") }
    static var helpFaqLocationDescription: String { return Localization.string(for: "help.faq.location.description") }
    static var helpFaqAnonymousTitle: String { return Localization.string(for: "help.faq.anonymous.title") }
    static var helpFaqAnonymousDescription1: String { return Localization.string(for: "help.faq.anonymous.description_1") }
    static var helpFaqAnonymousDescription2: String { return Localization.string(for: "help.faq.anonymous.description_2") }
    static var helpFaqNotificationTitle: String { return Localization.string(for: "help.faq.notification.title") }
    static var helpFaqNotificationDescription: String { return Localization.string(for: "help.faq.notification.description") }
    static var helpFaqUploadKeysTitle: String { return Localization.string(for: "help.faq.upload_keys.title") }
    static var helpFaqUploadKeysDescription: String { return Localization.string(for: "help.faq.upload_keys.description") }
    static var helpFaqBluetoothTitle: String { return Localization.string(for: "help.faq.bluetooth.title") }
    static var helpFaqBluetoothDescription: String { return Localization.string(for: "help.faq.bluetooth.description") }
    static var helpFaqPowerUsageTitle: String { return Localization.string(for: "help.faq.power_usage.title") }
    static var helpFaqPowerUsageDescription: String { return Localization.string(for: "help.faq.power_usage.description") }
    static var helpFaqDeletionTitle: String { return Localization.string(for: "moreInformation.about.faq.deletion") }
    static var helpFaqDeletionDescription: String { return Localization.string(for: "moreInformation.about.faq.deletion.description") }
    static var helpRateAppTitle: String { return Localization.string(for: "about.review") }
    static var helpPrivacyPolicyTitle: String { return Localization.string(for: "help.faq.privacy_policy.title") }
    static var helpPrivacyPolicyLink: String { return Localization.string(for: "help.faq.privacy_policy.link", [currentLanguageIdentifier]) }
    static var helpColofonTitle: String { return Localization.string(for: "help.faq.colofon.title") }
    static var helpColofonLink: String { return Localization.string(for: "help.faq.colofon.link", [currentLanguageIdentifier]) }
    static var helpAccessibilityTitle: String { return Localization.string(for: "help.faq.accessibility.title") }
    static var helpAccessibilityLink: String { return Localization.string(for: "help.faq.accessibility.link", [currentLanguageIdentifier]) }
    static var helpPauseAppTitle: String { return Localization.string(for: "help.pause_app.title") }
    static var helpPauseAppDescription: String { return Localization.string(for: "help.pause_app.description") }
    static var helpOtherCountriesTitle: String { return Localization.string(for: "help.apps_other_countries.title") }
    static var helpOtherCountriesDescription: String { return Localization.string(for: "help.apps_other_countries.description") }

    // MARK: - About - What the app do

    static var helpWhatAppDoesTitle: String { return Localization.string(for: "help.what_does_the_app_do.title") }
    static var helpWhatAppDoesProtectTitle: String { return Localization.string(for: "help.what_does_the_app_do.protect.title") }
    static var helpWhatAppDoesProtectDescription: String { return Localization.string(for: "help.what_does_the_app_do.protect.description") }
    static var helpWhatAppDoesNotifyTitle: String { return Localization.string(for: "help.what_does_the_app_do.notify.title") }
    static var helpWhatAppDoesNotifyDescription: String { return Localization.string(for: "help.what_does_the_app_do.notify.description") }
    static var helpWhatAppDoesBluetoothTitle: String { return Localization.string(for: "help.what_does_the_app_do.bluetooth.title") }
    static var helpWhatAppDoesBluetoothDescription: String { return Localization.string(for: "help.what_does_the_app_do.bluetooth.description") }
    static var helpWhatAppDoesExampleCycleTitle: String { return Localization.string(for: "help.what_does_the_app_do.example.cycle.title") }
    static var helpWhatAppDoesExampleCycleDescription: String { return Localization.string(for: "help.what_does_the_app_do.example.cycle.description") }
    static var helpWhatAppDoesExampleTrainTitle: String { return Localization.string(for: "help.what_does_the_app_do.example.train.title") }
    static var helpWhatAppDoesExampleTrainDescription: String { return Localization.string(for: "help.what_does_the_app_do.example.train.description") }

    // MARK: - About - TechnicalInformation

    static var helpTechnicalInformationTitle: String { return Localization.string(for: "help.technical_explanation.title") }
    static var helpTechnicalInformationStep1Title: String { return Localization.string(for: "help.technical_explanation.step1.title") }
    static var helpTechnicalInformationStep1Description: String { return Localization.string(for: "help.technical_explanation.step1.description") }
    static var helpTechnicalInformationStep2Title: String { return Localization.string(for: "help.technical_explanation.step2.title") }
    static var helpTechnicalInformationStep2Description: String { return Localization.string(for: "help.technical_explanation.step2.description") }
    static var helpTechnicalInformationStep3Title: String { return Localization.string(for: "help.technical_explanation.step3.title") }
    static var helpTechnicalInformationStep3Description: String { return Localization.string(for: "help.technical_explanation.step3.description") }
    static var helpTechnicalInformationStep4Title: String { return Localization.string(for: "help.technical_explanation.step4.title") }
    static var helpTechnicalInformationStep4Description: String { return Localization.string(for: "help.technical_explanation.step4.description") }
    static var helpTechnicalInformationStep5Title: String { return Localization.string(for: "help.technical_explanation.step5.title") }
    static var helpTechnicalInformationStep5Description: String { return Localization.string(for: "help.technical_explanation.step5.description") }
    static var helpTechnicalInformationGithubTitle: String { return Localization.string(for: "help.technical_explanation.github.title") }
    static var helpTechnicalInformationGithubSubtitle: String { return Localization.string(for: "help.technical_explanation.github.subtitle") }

    // MARK: - Help/MoreInformation - Notification Received

    static var helpReceivedNotificationMeaningTitle: String { return Localization.string(for: "help.what_does_notification_mean.title") }
    static var helpReceivedNotificationMeaningDescription1: String { return Localization.string(for: "help.what_does_notification_mean.description1") }
    static var helpReceivedNotificationMeaningDescription2: String { return Localization.string(for: "help.what_does_notification_mean.description2") }
    static var helpReceivedNotificationReportTitle: String { return Localization.string(for: "help.what_does_report_look_like.title") }
    static var helpReceivedNotificationReportDescription: String { return Localization.string(for: "help.what_does_report_look_like.description") }
    static var helpReceivedNotificationExample: String { return Localization.string(for: "help.notification.example") }
    static var helpReceivedNotificationWhatToDoTitle: String { return Localization.string(for: "help.what_to_do_with_notification.title") }
    static var helpReceivedNotificationWhatToDoDescription: String { return Localization.string(for: "help.what_to_do_with_notification.description") }
    static var helpReceivedNotificationOtherReportsTitle: String { return Localization.string(for: "help.other_reports.title") }
    static var helpReceivedNotificationOtherReportsDescription: String { return Localization.string(for: "help.other_reports.description") }
    static var helpOtherWhatDoesReportSayTitle: String { return Localization.string(for: "help.other_what_does_report_say.title") }

    // MARK: - Message

    static var messageDefaultTitle: String { return Localization.string(for: "message.default.title") }
    static var messageDefaultBody: String { return Localization.string(for: "message.default.body") }
    static var messageTitle: String { return Localization.string(for: "message.title") }
    static var messageButtonTitle: String { return Localization.string(for: "message.button.title") }

    static var notificationEnStatusNotActive: String { Localization.string(for: "notification.en.statusNotActive") }

    static var notificationUploadFailedNotification: String { Localization.string(for: "notification.upload.failed.notification") }
    static var notificationUploadFailedHeader: String { Localization.string(for: "notification.upload.failed.header") }
    static var notificationUploadFailedTitle: String { Localization.string(for: "notification.upload.failed.title") }
    static var notificationUploadFailedContent: String { Localization.string(for: "notification.upload.failed.content") }

    // MARK: - Main

    static var mainConfirmNotificationRemovalTitle: String { Localization.string(for: "main.confirmNotificationRemoval.title") }
    static var mainConfirmNotificationRemovalMessage: String { Localization.string(for: "main.confirmNotificationRemoval.message") }
    static var mainConfirmNotificationRemovalConfirm: String { Localization.string(for: "main.confirmNotificationRemoval.confirm") }

    // MARK: - Status

    static var statusIconAccessibilityOk: String { return Localization.string(for: "status.icon.accessibility.ok") }
    static var statusIconAccessibilityInactive: String { return Localization.string(for: "status.icon.accessibility.inactive") }
    static var statusIconAccessibilityNotified: String { return Localization.string(for: "status.icon.accessibility.notified") }
    static var statusAppState: String { return Localization.string(for: "status.appState") }
    static var statusAppStateInactiveTitle: String { return Localization.string(for: "status.appState.inactive.title") }
    static var statusAppStateInactiveDescription: String { return Localization.string(for: "status.appState.inactive.description") }
    static var statusAppStateInactiveNotification: String { return Localization.string(for: "status.appState.inactive.notification") }
    static var statusAppStateInactiveNoRecentUpdatesDescription: String { return Localization.string(for: "status.appState.inactive.no_recent_updates.description") }
    static var statusAppStateCardTitle: String { return Localization.string(for: "status.appState.card.title") }
    static var statusAppStateCardDescription: String { return Localization.string(for: "status.appState.card.description") }
    static var statusAppStateCardNoRecentUpdatesDescription: String { return Localization.string(for: "status.appState.card.no_recent_updates.description") }
    static var statusAppStateCardButton: String { return Localization.string(for: "status.appState.card.button") }
    static var statusAppStateCardTryAgain: String { return Localization.string(for: "status.appState.card.try_again") }
    static var statusActiveDescription: String { return Localization.string(for: "status.active.description") }

    static func statusNotifiedDaysAgo(days: Int) -> String {
        switch days {
        case 0: return Localization.string(for: "status.notified.today")
        case 1: return Localization.string(for: "status.notified.days_ago_one", ["\(days)"])
        default: return Localization.string(for: "status.notified.days_ago_other", ["\(days)"])
        }
    }

    static func statusNotifiedDescription(_ one: String, two: String) -> String { return Localization.string(for: "status.notified.description", [one, two]) }
    static var statusNotifiedMoreInfo: String { return Localization.string(for: "status.notified.moreInfo") }
    static var statusNotifiedRemoveNotification: String { return Localization.string(for: "status.notified.removeNotification") }

    static var moreInformationHeaderTitle: String { return Localization.string(for: "moreInformation.headerTitle") }
    static var moreInformationHeaderTitleUppercased: String { return Localization.string(for: "moreInformation.headerTitle").uppercased() }

    static var moreInformationCellAboutTitle: String { return Localization.string(for: "moreInformation.cell.about.title") }
    static var moreInformationCellAboutSubtitle: String { return Localization.string(for: "moreInformation.cell.about.subtitle") }

    static var moreInformationCellSettingsTitle: String { return Localization.string(for: "moreInformation.cell.settings.title") }
    static var moreInformationCellSettingsSubtitle: String { return Localization.string(for: "moreInformation.cell.settings.subtitle") }

    static var moreInformationCellShareTitle: String { return Localization.string(for: "moreInformation.cell.share.title") }
    static var moreInformationCellShareSubtitle: String { return Localization.string(for: "moreInformation.cell.share.subtitle") }

    static var moreInformationCellReceivedNotificationTitle: String { return Localization.string(for: "moreInformation.cell.receivedNotification.title") }
    static var moreInformationCellReceivedNotificationSubtitle: String { return Localization.string(for: "moreInformation.cell.receivedNotification.subtitle") }

    static var moreInformationCellRequestTestTitle: String { return Localization.string(for: "moreInformation.cell.requestTest.title") }
    static var moreInformationCellRequestTestSubtitle: String { return Localization.string(for: "moreInformation.cell.requestTest.subtitle") }

    static var moreInformationCellInfectedTitle: String { return Localization.string(for: "moreInformation.cell.infected.title") }
    static var moreInformationCellInfectedSubtitle: String { return Localization.string(for: "moreInformation.cell.infected.subtitle") }

    static var moreInformationInfoTitle: String { return Localization.string(for: "moreInformation.info.title") }

    static var moreInformationComplaintsItem1: String { return Localization.string(for: "moreInformation.complaints.item1") }
    static var moreInformationComplaintsItem2: String { return Localization.string(for: "moreInformation.complaints.item2") }
    static var moreInformationComplaintsItem3: String { return Localization.string(for: "moreInformation.complaints.item3") }
    static var moreInformationComplaintsItem4: String { return Localization.string(for: "moreInformation.complaints.item4") }
    static var moreInformationComplaintsItem5: String { return Localization.string(for: "moreInformation.complaints.item5") }
    static var moreInformationComplaintsTitle: String { return Localization.string(for: "moreInformation.complaints.title") }

    // MARK: - MoreInformation | About

    static var moreInformationAboutTitle: String { return Localization.string(for: "moreInformation.about.title") }
    static var aboutTechnicalInformationTitle: String { return Localization.string(for: "moreInformation.about.technical.title") }
    static var aboutTechnicalInformationDescription: String { return Localization.string(for: "moreInformation.about.technical.description") }
    static var aboutAppInformationTitle: String { return Localization.string(for: "moreInformation.about.onboarding.title") }
    static var aboutAppInformationDescription: String { return Localization.string(for: "moreInformation.about.onboarding.description") }
    static var aboutHelpdeskTitle: String { return Localization.string(for: "moreInformation.about.helpdesk.title") }
    static var aboutHelpdeskSubtitle: String { return Localization.string(for: "moreInformation.about.helpdesk.subtitle") }
    static var aboutInteroperabilityTitle: String { return Localization.string(for: "moreInformation.about.interoperability.title") }
    static var aboutInteroperabilityFAQLink: String {
        let interopURLLanguage = Localization.SupportedLanguageIdentifier(rawValue: .currentLanguageIdentifier) ?? .en
        return Localization.string(for: .interoperabilityFAQLink, [interopURLLanguage.rawValue])
    }

    // MARK: - MoreInformation | Settings

    static var moreInformationSettingsTitle: String { return Localization.string(for: "moreInformation.settings.title") }
    static var moreInformationSettingsDescription: String { return Localization.string(for: "moreInformation.settings.description") }
    static var moreInformationSettingsStep1: String { return Localization.string(for: "moreInformation.settings.step1") }
    static var moreInformationSettingsStep2: String { return Localization.string(for: "moreInformation.settings.step2") }
    static var moreInformationSettingsStep2RowTitle: String { return Localization.string(for: "moreInformation.settings.step2.row.title") }
    static var moreInformationSettingsButton: String { return Localization.string(for: "moreInformation.settings.button") }

    // MARK: - MoreInformation | Share

    static var moreInformationShareTitle: String { return Localization.string(for: "moreInformation.share.title") }
    static var moreInformationShareContent: String { return Localization.string(for: "moreInformation.share.description") }
    static var moreInformationShareButton: String { return Localization.string(for: "moreInformation.share.action") }

    // MARK: - MoreInformation | Infected

    static var moreInformationInfectedTitle: String { return Localization.string(for: "moreInformation.infected.title") }
    static var moreInformationInfectedLoading: String { return Localization.string(for: "moreInformation.infected.loading") }
    static var moreInformationInfectedUpload: String { return Localization.string(for: "moreInformation.infected.upload") }

    static var moreInformationInfectedError: String { return Localization.string(for: "moreInformation.infected.error") }
    static var moreInformationInfectedErrorUpload: String { return Localization.string(for: "moreInformation.infected.error.upload") }
    static var moreInformationInfectedErrorUploadingCodes: String { return Localization.string(for: "moreInformation.infected.error.uploadCodes") }

    static var moreInformationInfectedSectionAnonymouslyWarnOthersTitle: String { return Localization.string(for: "moreInformation.infected.section.anonomuslyWarnOthers.title") }
    static var moreInformationInfectedSectionAnonymouslyWarnOthersContent: String { return Localization.string(for: "moreInformation.infected.section.anonomuslyWarnOthers.content") }

    static var moreInformationInfectedSectionControlCodeTitle: String { return Localization.string(for: "moreInformation.infected.section.controlCode.title") }
    static var moreInformationInfectedSectionUploadCodesTitle: String { return Localization.string(for: "moreInformation.infected.section.uploadCodes.title") }
    static var moreInformationInfectedSectionControlCodeContent: String { return Localization.string(for: "moreInformation.infected.section.controlCode.content") }

    static var moreInformationInfectedHeader: String { return Localization.string(for: "moreInformation.infected.header") }
    static var moreInformationInfectedHowDoesItWork: String { return Localization.string(for: "moreInformation.infected.how_does_it_work") }
    static var moreInformationInfectedStep1: String { return Localization.string(for: "moreInformation.infected.step1") }
    static var moreInformationInfectedStep2: String { return Localization.string(for: "moreInformation.infected.step2") }
    static var moreInformationInfectedStep3: String { return Localization.string(for: "moreInformation.infected.step3") }

    static var moreInformationThankYouTitle: String { return Localization.string(for: "moreInformation.thankyou.title") }
    static var moreInformationThankYouSectionTitle: String { return Localization.string(for: "moreInformation.thankyou.section.title") }
    static var moreInformationThankYouSectionHeader: String { return Localization.string(for: "moreInformation.thankyou.section.header") }
    static var moreInformationThankYouSectionFooter: String { return Localization.string(for: "moreInformation.thankyou.section.footer") }
    static var moreInformationThankYouListItem1: String { return Localization.string(for: "moreInformation.thankyou.list.item1") }
    static var moreInformationThankYouListItem2: String { return Localization.string(for: "moreInformation.thankyou.list.item2") }
    static var moreInformationThankYouListItem3: String { return Localization.string(for: "moreInformation.thankyou.list.item3") }
    static var moreInformationThankYouInfo: String { return Localization.string(for: "moreInformation.thankyou.info.title") }

    // MARK: - MoreInformation | Received Notification

    static var moreInformationReceivedNotificationTitle: String { return Localization.string(for: "moreInformation.receivedNotification.title") }
    static var moreInformationReceivedNotificationButtonTitle: String { return Localization.string(for: "moreInformation.receivedNotification.button.title") }
    static var moreInformationReceivedNotificationNotificationExplanationTitle: String { return Localization.string(for: "moreInformation.receivedNotification.notificationExplanation.title") }
    static var moreInformationReceivedNotificationNotificationExplanationContent: String { return Localization.string(for: "moreInformation.receivedNotification.notificationExplanation.content") }
    static var moreInformationReceivedNotificationDoCoronaTestTitle: String { return Localization.string(for: "moreInformation.receivedNotification.doCoronaTest.title") }
    static var moreInformationReceivedNotificationDoCoronaTestContent: String { return Localization.string(for: "moreInformation.receivedNotification.doCoronaTest.content") }

    // MARK: - MoreInformation | Request Test

    static var moreInformationRequestTestTitle: String { return Localization.string(for: "moreInformation.requestTest.title") }
    static var moreInformationRequestTestButtonTitle: String { return Localization.string(for: "moreInformation.requestTest.button.title") }
    static var moreInformationRequestTestReceivedNotificationTitle: String { return Localization.string(for: "moreInformation.requestTest.receivedNotification.title") }
    static var moreInformationRequestTestReceivedNotificationContent: String { return Localization.string(for: "moreInformation.requestTest.receivedNotification.content") }

    static var moreInformationNotificationMeasuresTitle: String { return Localization.string(for: "moreInformation.notification.measures.title") }
    static var moreInformationNotificationMeasuresStep1: String { return Localization.string(for: "moreInformation.notification.measures.step1") }
    static var moreInformationNotificationMeasuresStep2: String { return Localization.string(for: "moreInformation.notification.measures.step2") }
    static var moreInformationNotificationMeasuresStep3: String { return Localization.string(for: "moreInformation.notification.measures.step3") }

    static var moreInformationSituationTitle: String { return Localization.string(for: "moreInformation.situation.title") }
    static var moreInformationSituationStep1: String { return Localization.string(for: "moreInformation.situation.step1") }
    static var moreInformationSituationStep2: String { return Localization.string(for: "moreInformation.situation.step2") }
    static var moreInformationSituationStep3: String { return Localization.string(for: "moreInformation.situation.step3") }

    static var moreInformationRequestTestComplaints: String { return Localization.string(for: "moreInformation.requestTest.complaints") }
    static var moreInformationRequestTestLink: String { return Localization.string(for: "moreInformation.requestTest.link") }
    static var moreInformationRequestTestPhone: String { Localization.string(for: "moreInformation.requestTest.phone") }

    // MARK: - Cards | Exposure Off

    static var cardsExposureOffTitle: String { return Localization.string(for: "cards.exposureOff.title") }
    static var cardsExposureOffContent: String { return Localization.string(for: "cards.exposureOff.content") }
    static var cardsExposureOffAction: String { return Localization.string(for: "cards.exposureOff.action") }

    // MARK: - Cards | Bluetooth Off

    static var cardsBluetoothOffTitle: String { return Localization.string(for: "cards.bluetoothOff.title") }
    static var cardsBluetoothOffContent: String { return Localization.string(for: "cards.bluetoothOff.content") }
    static var cardsBluetoothOffAction: String { return Localization.string(for: "cards.bluetoothOff.action") }

    // MARK: - Cards | No Internet

    static var cardsNoInternetTitle: String { return Localization.string(for: "cards.noInternet.title") }
    static var cardsNoInternetContent: String { return Localization.string(for: "cards.noInternet.content") }
    static var cardsNoInternetAction: String { return Localization.string(for: "cards.noInternet.action") }

    // MARK: - Cards | Notifications Off

    static var cardsNotificationsOffTitle: String { return Localization.string(for: "cards.notificationsOff.title") }
    static var cardsNotificationsOffContent: String { return Localization.string(for: "cards.notificationsOff.content") }
    static var cardsNotificationsOffAction: String { return Localization.string(for: "cards.notificationsOff.action") }

    // MARK: - Cards | Interop Announcement

    static var cardsInteropAnnouncementTitle: String { return Localization.string(for: "cards.interopannouncement.title") }
    static var cardsInteropAnnouncementContent: String { return Localization.string(for: "cards.interopannouncement.content") }
    static var cardsInteropAnnouncementAction: String { return Localization.string(for: "cards.interopannouncement.action") }
    static var cardsInteropAnnouncementSecondaryAction: String { return Localization.string(for: "cards.interopannouncement.secondaryaction") }
    static var cardsInteropabilityURL: String {
        let interopURLLanguage = Localization.SupportedLanguageIdentifier(rawValue: .currentLanguageIdentifier) ?? .en
        return Localization.string(for: .interoperabilityLink, [interopURLLanguage.rawValue])
    }

    // MARK: - Enable Settings | Exposure Notifications

    static var enableSettingsExposureNotificationsTitle: String { return Localization.string(for: "enableSettings.exposureNotifications.title") }
    static var enableSettingsExposureNotificationsAction: String { return Localization.string(for: "enableSettings.exposureNotifications.action") }
    static var enableSettingsExposureNotificationsStep1: String { return Localization.string(for: "enableSettings.exposureNotifications.step1") }
    static var enableSettingsExposureNotificationsStep2: String { return Localization.string(for: "enableSettings.exposureNotifications.step2") }
    static var enableSettingsExposureNotificationsStep2ActionTitle: String { return Localization.string(for: "enableSettings.exposureNotifications.step2.action.title") }

    // MARK: - Enable Settings | Exposure Notifications | iOS 13.7+

    static var enableSettingsExposureNotifications137Step2: String { return Localization.string(for: "enableSettings.exposureNotifications.137.step2") }
    static var enableSettingsExposureNotifications137Step2ActionTitle: String { return Localization.string(for: "enableSettings.exposureNotifications.137.step2.action.title") }
    static var enableSettingsExposureNotifications137Step3: String { return Localization.string(for: "enableSettings.exposureNotifications.137.step3") }
    static var enableSettingsExposureNotifications137Step3ActionTitle: String { return Localization.string(for: "enableSettings.exposureNotifications.137.step3.action.title") }
    static var enableSettingsExposureNotifications137Step4: String { return Localization.string(for: "enableSettings.exposureNotifications.137.step4") }
    static var enableSettingsExposureNotifications137Step4ActionTitle: String { return Localization.string(for: "enableSettings.exposureNotifications.137.step4.action.title") }

    // MARK: - Enable Settings | Bluetooth

    static var enableSettingsBluetoothTitle: String { return Localization.string(for: "enableSettings.bluetooth.title") }
    static var enableSettingsBluetoothAction: String { return Localization.string(for: "enableSettings.bluetooth.action") }
    static var enableSettingsBluetoothStep1: String { return Localization.string(for: "enableSettings.bluetooth.step1") }
    static var enableSettingsBluetoothStep2: String { return Localization.string(for: "enableSettings.bluetooth.step2") }
    static var enableSettingsBluetoothStep2ActionTitle: String { return Localization.string(for: "enableSettings.bluetooth.step2.action.title") }

    // MARK: - Enable Settings | Local Notifications

    static var enableSettingsLocalNotificationsTitle: String { return Localization.string(for: "enableSettings.localNotifications.title") }
    static var enableSettingsLocalNotificationsAction: String { return Localization.string(for: "enableSettings.localNotifications.action") }
    static var enableSettingsLocalNotificationsStep1: String { return Localization.string(for: "enableSettings.localNotifications.step1") }
    static var enableSettingsLocalNotificationsStep2: String { return Localization.string(for: "enableSettings.localNotifications.step2") }
    static var enableSettingsLocalNotificationsStep2ActionTitle: String { return Localization.string(for: "enableSettings.localNotifications.step2.action.title") }
    static var enableSettingsLocalNotificationsStep3: String { return Localization.string(for: "enableSettings.localNotifications.step3") }
    static var enableSettingsLocalNotificationsStep3ActionTitle: String { return Localization.string(for: "enableSettings.localNotifications.step3.action.title") }

    // MARK: - Exposure Notification Received - User Explanation

    static func exposureNotificationUserExplanation(_ one: String) -> String { return Localization.string(for: "exposure.notification.userExplanation", [one]) }

    static func exposureNotificationReminder(_ one: String) -> String { return Localization.string(for: "exposure.notification.reminder", [one]) }

    // MARK: - Privacy Agreement

    static var privacyAgreementTitle: String { return Localization.string(for: "privacyAgreement.title") }
    static var privacyAgreementMessage: String { return Localization.string(for: "privacyAgreement.message") }
    static var privacyAgreementMessageLink: String { return Localization.string(for: "privacyAgreement.message.link") }
    static var privacyAgreementStepsTitle: String { return Localization.string(for: "privacyAgreement.steps.title") }
    static var privacyAgreementStep0: String { return Localization.string(for: "privacyAgreement.list.step0") }
    static var privacyAgreementStep1: String { return Localization.string(for: "privacyAgreement.list.step1") }
    static var privacyAgreementStep2: String { return Localization.string(for: "privacyAgreement.list.step2") }
    static var privacyAgreementStep3: String { return Localization.string(for: "privacyAgreement.list.step3") }
    static var privacyAgreementStep4: String { return Localization.string(for: "privacyAgreement.list.step4") }
    static var privacyAgreementConsentButton: String { return Localization.string(for: "privacyAgreement.consent.button") }

    // MARK: - Message (Change of contamination)

    static var contaminationChanceTitle: String { return Localization.string(for: "contamination.title") }

    static var contaminationChanceNearSomeoneWithCoronaTitle: String { return Localization.string(for: "contamination.near_someone_with_corona.title") }
    static func contaminationChanceNearSomeoneWithCoronaDescription(_ one: String) -> String { return Localization.string(for: "contamination.near_someone_with_corona.description", [one]) }
    static var contaminationChanceWhatToDoTitle: String { return Localization.string(for: "contamination.what_to_do.title") }
    static func contaminationChanceWhatToDoStep1(_ one: String) -> String { return Localization.string(for: "contamination.what_to_do.step1", [one]) }
    static func contaminationChanceWhatToDoStep2(_ one: String) -> String { return Localization.string(for: "contamination.what_to_do.step2", [one]) }
    static var contaminationChanceWhatToDoStep3: String { return Localization.string(for: "contamination.what_to_do.step3") }
    static var contaminationChanceWhatToDoDescription: String { return Localization.string(for: "contamination.what_to_do.description") }
    static func contaminationChanceStayHomeTitle(_ one: String) -> String { return Localization.string(for: "contamination.stay_home.title", [one]) }
    static var contaminationChanceStayHomeStep1: String { return Localization.string(for: "contamination.stay_home.step1") }
    static var contaminationChanceStayHomeStep2: String { return Localization.string(for: "contamination.stay_home.step2") }
    static var contaminationChanceStayHomeStep3: String { return Localization.string(for: "contamination.stay_home.step3") }
    static var contaminationChanceVisitorsTitle: String { return Localization.string(for: "contamination.visitors.title") }
    static var contaminationChanceVisitorsStep1: String { return Localization.string(for: "contamination.visitors.step1") }
    static var contaminationChanceMedicalHelpTitle: String { return Localization.string(for: "contamination.medical_help.title") }
    static var contaminationChanceMedicalHelpStep1: String { return Localization.string(for: "contamination.medical_help.step1") }
    static var contaminationChanceMedicalHelpStep2: String { return Localization.string(for: "contamination.medical_help.step2") }
    static func contaminationChanceAfterTitle(_ one: String) -> String { return Localization.string(for: "contamination.after.title", [one]) }
    static func contaminationChanceAfterDescription(_ one: String) -> String { return Localization.string(for: "contamination.after.description", [one]) }
    static var contaminationChanceComplaintsTitle: String { return Localization.string(for: "contamination.complaints.title") }
    static var contaminationChanceComplaintsStep1: String { return Localization.string(for: "contamination.complaints.step1") }
    static var contaminationChanceComplaintsStep2: String { return Localization.string(for: "contamination.complaints.step2") }
    static var contaminationChanceComplaintsStep3: String { return Localization.string(for: "contamination.complaints.step3") }
    static var contaminationChanceComplaintsStep4: String { return Localization.string(for: "contamination.complaints.step4") }
    static var contaminationChanceComplaintsStep5: String { return Localization.string(for: "contamination.complaints.step5") }
    static var contaminationChanceComplaintsStep6: String { return Localization.string(for: "contamination.complaints.step6") }

    func attributed() -> NSMutableAttributedString {
        return NSMutableAttributedString(string: self)
    }

    func attributedStrings() -> [NSMutableAttributedString] {
        let paragraph = "\n\n"
        let strings = self.components(separatedBy: paragraph)

        return strings.enumerated().map { (index, element) -> NSMutableAttributedString in
            let value = index < strings.count - 1 ? element + "\n" : element
            return NSMutableAttributedString(string: value)
        }
    }

    static var currentLanguageIdentifier: String {
        #if DEBUG
            if let overriddenCurrentLanguageIdentifier = LocalizationOverrides.overriddenCurrentLanguageIdentifier {
                return overriddenCurrentLanguageIdentifier
            }
        #endif

        let defaultLanguageIdentifier = "en"
        let supportedLanguageCodes = Bundle.main.localizations

        guard let languageCode = Locale.current.languageCode else {
            return defaultLanguageIdentifier
        }

        return supportedLanguageCodes.contains(languageCode) ? languageCode : defaultLanguageIdentifier
    }
}
