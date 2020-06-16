/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

final class OnboardingStep: NSObject {

    var attributedTitle: NSAttributedString = NSAttributedString(string: "")
    var attributedContent: NSAttributedString = NSAttributedString(string: "")
    
    var image: UIImage = UIImage()
    var buttonTitle: String = ""
    var isExample: Bool = false

    init(theme: Theme, title: String, content: String, image: UIImage, buttonTitle: String, isExample: Bool) {

        self.image = image
        self.buttonTitle = buttonTitle
        self.isExample = isExample
        
        let attributedTitleString = NSMutableAttributedString()
        
        if isExample {
            attributedTitleString.append(.make(text: Localized("example") + "\n\n", font: .systemFont(ofSize: 15, weight: .bold), textColor: theme.colors.secondary))
        }
        
        attributedTitleString.append( .makeFromHtml(text: title, font: .boldSystemFont(ofSize: 22), textColor: .black))
        
        self.attributedTitle = attributedTitleString
        self.attributedContent = .makeFromHtml(text: content, font: .systemFont(ofSize: 17), textColor: theme.colors.gray)
    }
}
