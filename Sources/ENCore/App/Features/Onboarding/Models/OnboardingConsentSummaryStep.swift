/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

final class OnboardingConsentSummaryStep: NSObject {

    var title: NSAttributedString = NSAttributedString(string: "")
    var image: UIImage = UIImage()

    init(theme: Theme, title: String, image: UIImage?) {

        self.title = .makeFromHtml(text: title, font: theme.fonts.body, textColor: theme.colors.gray)
        if let image = image { self.image = image }
    }
}
