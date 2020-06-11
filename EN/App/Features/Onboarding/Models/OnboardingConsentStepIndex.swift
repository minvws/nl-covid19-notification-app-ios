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
}

final class OnboardingConsentStep: NSObject {

    var step: OnboardingConsentStepIndex
    var title: String = ""
    var content: String = ""
    var image: UIImage?
    var hasImage: Bool { get { return self.image != nil } }
    var summarySteps: [OnboardingConsentSummaryStep]?
    var hasSummarySteps: Bool {
        get {
            guard let summarySteps = self.summarySteps else { return false }
            return !summarySteps.isEmpty
        }
    }
    var primaryButtonTitle: String = ""
    var secondaryButtonTitle: String = ""
    var hasNavigationBarSkipButton: Bool = false
    var attributedText: NSAttributedString = NSAttributedString(string: "")

    init(step: OnboardingConsentStepIndex,
        title: String,
        content: String,
        image: UIImage?,
        summarySteps: [OnboardingConsentSummaryStep]?,
        primaryButtonTitle: String,
        secondaryButtonTitle: String,
        hasNavigationBarSkipButton: Bool) {

        self.step = step
        self.title = title
        self.content = content
        self.image = image
        self.summarySteps = summarySteps
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.hasNavigationBarSkipButton = hasNavigationBarSkipButton
        
        let attributedString = NSMutableAttributedString()

        let newLineAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10)]
        let newLine = NSAttributedString(string: "\n\n", attributes: newLineAttributes)

        let titleStringAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 22, weight: .bold), .foregroundColor: UIColor.black]
        let titleString = NSAttributedString(string: title, attributes: titleStringAttributes)

        let contentStringAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17, weight: .regular), .foregroundColor: UIColor.grayColor]
        let contentString = NSAttributedString(string: content, attributes: contentStringAttributes)

        for string in [titleString, newLine, contentString] { attributedString.append(string) }

        self.attributedText = attributedString
    }
}
