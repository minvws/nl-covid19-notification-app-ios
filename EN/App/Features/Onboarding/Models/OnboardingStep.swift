/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

final class OnboardingStep: NSObject {

    var title: String = ""
    var content: String = ""
    var image: UIImage = UIImage()
    var buttonTitle: String = ""
    var isExample: Bool = false
    var attributedText: NSAttributedString = NSAttributedString(string: "")

    init(title: String, content: String, image: UIImage, buttonTitle: String, isExample: Bool) {
        
        self.title = title
        self.content = content
        self.image = image
        self.buttonTitle = buttonTitle
        self.isExample = isExample

        let attributedString = NSMutableAttributedString()
        let newLine: NSAttributedString = .make(text: "\n\n", font: .systemFont(ofSize: 10), textColor: .black)
        let exampleString: NSAttributedString = .make(text: Localized("example"), font: .systemFont(ofSize: 15, weight: .bold), textColor: UIColor.secondaryColor)
        let titleString: NSAttributedString = .make(text: title, font: .boldSystemFont(ofSize: 22), textColor: .black)
        let contentString: NSAttributedString = .make(text: content, font: .systemFont(ofSize: 17), textColor: .grayColor)

        if isExample {
            for string in [exampleString, newLine, titleString, newLine, contentString] { attributedString.append(string) }
        } else {
            for string in [titleString, newLine, contentString] { attributedString.append(string) }
        }

        self.attributedText = attributedString
    }
}
