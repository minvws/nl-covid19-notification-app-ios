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

    // MARK: - Init

    init(theme: Theme, testPhaseStream: AnyPublisher<Bool, Never>) {
        questionsSection = AboutSection(title: .helpSubtitle, entries: [
            .question(title: .helpFaqReasonTitle, answer: .helpFaqReasonDescription),
            .question(title: .helpFaqLocationTitle, answer: .helpFaqLocationDescription),
            .question(title: .helpFaqAnonymousTitle, answer: .helpFaqAnonymousDescription1 + "\n\n" + .helpFaqAnonymousDescription2),
            .question(title: .helpFaqNotificationTitle, answer: .helpFaqNotificationDescription),
            .question(title: .helpFaqUploadKeysTitle, answer: .helpFaqUploadKeysDescription),
            .question(title: .helpFaqBluetoothTitle, answer: .helpFaqBluetoothDescription),
            .question(title: .helpFaqPowerUsageTitle, answer: .helpFaqPowerUsageDescription),
            .question(title: .helpFaqDeletionTitle, answer: .helpFaqDeletionDescription)
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
