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

        let newLineAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10)]
        let newLine = NSAttributedString(string: "\n\n", attributes: newLineAttributes)

        let exampleStringAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 15, weight: .bold), .foregroundColor: UIColor.secondaryColor]
        let exampleString = NSAttributedString(string: Localized("example"), attributes: exampleStringAttributes)

        let titleStringAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 22, weight: .bold), .foregroundColor: UIColor.black]
        let titleString = NSAttributedString(string: title, attributes: titleStringAttributes)

        let contentStringAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17, weight: .regular), .foregroundColor: UIColor.grayColor]
        let contentString = NSAttributedString(string: content, attributes: contentStringAttributes)

        if isExample {
            for string in [exampleString, newLine, titleString, newLine, contentString] { attributedString.append(string) }
        } else {
            for string in [titleString, newLine, contentString] { attributedString.append(string) }
        }

        self.attributedText = attributedString
    }
}
