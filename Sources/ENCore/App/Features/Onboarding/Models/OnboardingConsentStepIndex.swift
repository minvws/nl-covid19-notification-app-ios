/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

enum OnboardingConsentStepIndex: Int {
    case en = 0
    case bluetooth
    case notifications
}

final class OnboardingConsentStep: NSObject {

    var step: OnboardingConsentStepIndex
    var attributedTitle: NSAttributedString = NSAttributedString(string: "")
    var attributedContent: NSAttributedString = NSAttributedString(string: "")
    var image: UIImage?
    var hasImage: Bool { return self.image != nil }
    var summarySteps: [OnboardingConsentSummaryStep]?
    var hasSummarySteps: Bool {
        guard let summarySteps = self.summarySteps else { return false }
        return !summarySteps.isEmpty
    }
    var primaryButtonTitle: String = ""
    var secondaryButtonTitle: String = ""
    var hasNavigationBarSkipButton: Bool = false

    init(step: OnboardingConsentStepIndex,
        theme: Theme,
        title: String,
        content: String,
        image: UIImage?,
        summarySteps: [OnboardingConsentSummaryStep]?,
        primaryButtonTitle: String,
        secondaryButtonTitle: String,
        hasNavigationBarSkipButton: Bool) {

        self.step = step
        self.image = image
        self.summarySteps = summarySteps
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.hasNavigationBarSkipButton = hasNavigationBarSkipButton

        self.attributedTitle = .makeFromHtml(text: title, font: .boldSystemFont(ofSize: 22), textColor: .black)
        self.attributedContent = .makeFromHtml(text: content, font: .systemFont(ofSize: 17), textColor: theme.colors.gray)
    }
}
