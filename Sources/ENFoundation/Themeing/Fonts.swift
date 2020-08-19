/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

public protocol Fonts {
    var largeTitle: UIFont { get }
    var title1: UIFont { get }
    var title2: UIFont { get }
    var title3: UIFont { get }
    var headline: UIFont { get }
    var body: UIFont { get }
    var bodyBold: UIFont { get }
    var callout: UIFont { get }
    var subhead: UIFont { get }
    var subheadBold: UIFont { get }
    var footnote: UIFont { get }
    var caption1: UIFont { get }
}

final class ENFonts: Fonts {
    // Using default textStyles from Apple typography guidelines:
    // https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography/
    // Table with point in sizes can be found on the link.

    var largeTitle: UIFont {
        font(textStyle: .largeTitle, isBold: true) // Size 34 points
    }

    var title1: UIFont {
        font(textStyle: .title1, isBold: true) // Size 28 points
    }

    var title2: UIFont {
        font(textStyle: .title2, isBold: true) // Size 22 points
    }

    var title3: UIFont {
        font(textStyle: .title3, isBold: true) // Size 20 points
    }

    var headline: UIFont {
        font(textStyle: .headline) // Size 17 points
    }

    var body: UIFont {
        font(textStyle: .body) // Size 17 points
    }

    var bodyBold: UIFont {
        font(textStyle: .body, isBold: true) // Size 17 points
    }

    var callout: UIFont {
        font(textStyle: .callout) // Size 16 points
    }

    var subhead: UIFont {
        font(textStyle: .subheadline) // Size 15 points
    }

    var subheadBold: UIFont {
        font(textStyle: .subheadline, isBold: true) // Size 15 points
    }

    var footnote: UIFont {
        font(textStyle: .footnote) // Size 13 points
    }

    var caption1: UIFont {
        font(textStyle: .caption1) // size 12 points
    }

    // MARK: - Private

    private func font(textStyle: UIFont.TextStyle, isBold: Bool = false) -> UIFont {
        var fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

        if isBold, let boldFontDescriptor = fontDescriptor.withSymbolicTraits(.traitBold) {
            fontDescriptor = boldFontDescriptor
        }

        return UIFont(descriptor: fontDescriptor, size: fontDescriptor.pointSize)
    }
}
