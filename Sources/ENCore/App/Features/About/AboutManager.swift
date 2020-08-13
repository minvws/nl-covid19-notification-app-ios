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
    fileprivate(set) var questions: [HelpQuestion]
}

final class AboutManager: AboutManaging {

    var didUpdate: (() -> ())?

    let questionsSection: AboutSection
    private(set) var aboutSection: AboutSection

    // MARK: - Init

    init(theme: Theme, testPhaseStream: AnyPublisher<Bool, Never>) {
        questionsSection = AboutSection(title: .helpSubtitle, questions: [
            HelpQuestion(theme: theme, question: .helpFaqReasonTitle, answer: .helpFaqReasonDescription),
            HelpQuestion(theme: theme, question: .helpFaqLocationTitle, answer: .helpFaqLocationDescription),
            HelpQuestion(theme: theme, question: .helpFaqAnonymousTitle, answer: .helpFaqAnonymousDescription1 + "\n\n" + .helpFaqAnonymousDescription2),
            HelpQuestion(theme: theme, question: .helpFaqNotificationTitle, answer: .helpFaqNotificationDescription),
            HelpQuestion(theme: theme, question: .helpFaqUploadKeysTitle, answer: .helpFaqUploadKeysDescription),
            HelpQuestion(theme: theme, question: .helpFaqBluetoothTitle, answer: .helpFaqBluetoothDescription),
            HelpQuestion(theme: theme, question: .helpFaqPowerUsageTitle, answer: .helpFaqPowerUsageDescription),
            HelpQuestion(theme: theme, question: .helpFaqDeletionTitle, answer: .helpFaqDeletionDescription)
        ])

        aboutSection = AboutSection(title: .moreInformationAboutTitle, questions: [
            HelpQuestion(theme: theme, question: .helpRateAppTitle, answer: nil),
            HelpQuestion(theme: theme, question: .helpPrivacyPolicyTitle, answer: "", link: .helpPrivacyPolicyLink),
            HelpQuestion(theme: theme, question: .helpAccessibilityTitle, answer: "", link: .helpAccessibilityLink),
            HelpQuestion(theme: theme, question: .helpColofonTitle, answer: "", link: .helpColofonLink)
        ])

        testPhaseStream
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { isTestPhase in
                if isTestPhase {
                    let question = HelpQuestion(theme: theme, question: .helpTestVersionTitle, answer: "", link: .helpTestVersionLink)
                    self.aboutSection.questions.append(question)
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
