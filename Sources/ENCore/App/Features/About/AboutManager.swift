/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import UIKit

/// @mockable
protocol AboutManaging: AnyObject {
    var questionsSection: AboutSection { get }
    var aboutSection: AboutSection { get }
    var appInformationEntry: AboutEntry { get }
    var technicalInformationEntry: AboutEntry { get }

    var didUpdate: (() -> ())? { get set }
}

struct AboutSection {
    let title: String
    fileprivate(set) var entries: [AboutEntry]
}

final class AboutManager: AboutManaging {

    var didUpdate: (() -> ())?

    let questionsSection: AboutSection
    private(set) var aboutSection: AboutSection

    let appInformationEntry: AboutEntry
    let technicalInformationEntry: AboutEntry

    // MARK: - Init

    init(testPhaseStream: AnyPublisher<Bool, Never>) {
        let reason = HelpQuestion(question: .helpFaqReasonTitle, answer: .helpFaqReasonDescription)
        let anonymous = HelpQuestion(question: .helpFaqAnonymousTitle, answer: .helpFaqAnonymousDescription1 + "<br><br>" + .helpFaqAnonymousDescription2)
        let location = HelpQuestion(question: .helpFaqLocationTitle, answer: .helpFaqLocationDescription)
        let notification = HelpQuestion(question: .helpFaqNotificationTitle, answer: .helpFaqNotificationDescription)
        let uploadKeys = HelpQuestion(question: .helpFaqUploadKeysTitle, answer: .helpFaqUploadKeysDescription)
        let bluetooth = HelpQuestion(question: .helpFaqBluetoothTitle, answer: .helpFaqBluetoothDescription)
        let power = HelpQuestion(question: .helpFaqPowerUsageTitle, answer: .helpFaqPowerUsageDescription)
        let deletion = HelpQuestion(question: .helpFaqDeletionTitle, answer: .helpFaqDeletionDescription)
        let pause = HelpQuestion(question: .helpPauseAppTitle, answer: .helpPauseAppDescription)
        let otherCountries = HelpQuestion(question: .helpOtherCountriesTitle, answer: .helpOtherCountriesDescription)

        let notificationExplanation = AboutEntry.notificationExplanation(title: String.moreInformationCellReceivedNotificationTitle,
                                                                         linkedContent: [
                                                                             AboutEntry.question(notification),
                                                                             AboutEntry.question(bluetooth),
                                                                             AboutEntry.question(reason)
                                                                         ])

        appInformationEntry = .appInformation(linkedContent: [
            AboutEntry.question(reason),
            AboutEntry.question(location),
            AboutEntry.question(anonymous)
        ])

        technicalInformationEntry = .technicalInformation(title: .aboutTechnicalInformationTitle, linkedContent: [
            AboutEntry.question(bluetooth),
            AboutEntry.question(deletion),
            AboutEntry.question(otherCountries)
        ])

        questionsSection = AboutSection(title: .helpSubtitle, entries: [
            .question(reason.appending(linkedContent: [
                technicalInformationEntry,
                notificationExplanation
            ])),

            .question(anonymous.appending(linkedContent: [
                technicalInformationEntry,
                notificationExplanation,
                AboutEntry.question(location)
            ])),

            .question(location.appending(linkedContent: [
                AboutEntry.question(bluetooth)
            ])),

            .question(notification.appending(linkedContent: [
                notificationExplanation,
                AboutEntry.question(bluetooth),
                AboutEntry.question(uploadKeys)
            ])),

            .question(uploadKeys.appending(linkedContent: [
                notificationExplanation,
                AboutEntry.question(anonymous),
                technicalInformationEntry
            ])),

            notificationExplanation,

            .question(bluetooth.appending(linkedContent: [
                AboutEntry.question(notification),
                AboutEntry.question(anonymous)
            ])),

            .question(power.appending(linkedContent: [
                AboutEntry.question(reason),
                AboutEntry.question(pause)
            ])),

            .question(deletion.appending(linkedContent: [
                AboutEntry.question(bluetooth),
                AboutEntry.question(pause)
            ])),

            .question(pause.appending(linkedContent: [
                AboutEntry.question(bluetooth),
                AboutEntry.question(power),
                AboutEntry.question(location)
            ])),

            .question(otherCountries.appending(linkedContent: [
                technicalInformationEntry,
                AboutEntry.question(notification),
                AboutEntry.question(location)
            ]))

        ])

        aboutSection = AboutSection(title: .moreInformationAboutTitle, entries: [
            .rate(title: .helpRateAppTitle),
            .link(title: .helpPrivacyPolicyTitle, link: .helpPrivacyPolicyLink),
            .link(title: .helpAccessibilityTitle, link: .helpAccessibilityLink),
            .link(title: .helpColofonTitle, link: .helpColofonLink)
        ])

        testPhaseStream
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { isTestPhase in
                if isTestPhase {
                    self.aboutSection.entries.append(.link(title: .helpTestVersionTitle, link: .helpTestVersionLink))
                    self.didUpdate?()
                }
            }).store(in: &disposeBag)
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - Private

    private var disposeBag = Set<AnyCancellable>()
}
