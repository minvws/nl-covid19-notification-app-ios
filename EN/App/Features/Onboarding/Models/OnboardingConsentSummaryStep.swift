/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

class OnboardingConsentSummaryStep: NSObject {

    var title: NSAttributedString = NSAttributedString(string: "")
    var image: UIImage = UIImage()

    init(title: NSAttributedString, image: UIImage?) {

        self.title = title
        if let image = image { self.image = image }
    }
}
