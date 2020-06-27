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
    var callout: UIFont { get }
    var subhead: UIFont { get }
    var subheadBold: UIFont { get }
    var footnote: UIFont { get }
    var caption1: UIFont { get }
}

final class ENFonts: Fonts {

    var largeTitle: UIFont {
        font(size: 34, weight: .bold, textStyle: .largeTitle)
    }

    var title1: UIFont {
        font(size: 28, weight: .bold, textStyle: .title1)
    }

    var title2: UIFont {
        font(size: 22, weight: .bold, textStyle: .title2)
    }

    var title3: UIFont {
        font(size: 20, weight: .bold, textStyle: .title3)
    }

    var headline: UIFont {
        font(size: 17, weight: .semibold, textStyle: .headline)
    }

    var body: UIFont {
        font(size: 17, weight: .regular, textStyle: .body)
    }

    var callout: UIFont {
        font(size: 16, weight: .regular, textStyle: .callout)
    }

    var subhead: UIFont {
        font(size: 15, weight: .regular, textStyle: .subheadline)
    }

    var subheadBold: UIFont {
        font(size: 15, weight: .bold, textStyle: .subheadline)
    }

    var footnote: UIFont {
        font(size: 13, weight: .regular, textStyle: .footnote)
    }

    var caption1: UIFont {
        font(size: 12, weight: .regular, textStyle: .caption1)
    }

    // MARK: - Private

    private func font(size: CGFloat, weight: UIFont.Weight, textStyle: UIFont.TextStyle) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        return fontMetrics.scaledFont(for: font)
    }
}
