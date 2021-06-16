/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

public protocol Colors: AnyObject {
    var primary: UIColor { get }
    var secondaryLight: UIColor { get }
    var tertiary: UIColor { get }
    var warning: UIColor { get }

    var gray: UIColor { get }

    var ok: UIColor { get }
    var notified: UIColor { get }
    var inactive: UIColor { get }
    var inactiveGray: UIColor { get }
    var disabled: UIColor { get }

    var statusGradientActive: UIColor { get }
    var statusGradientNotified: UIColor { get }
    var statusGradientPaused: UIColor { get }

    var navigationControllerBackground: UIColor { get }
    var viewControllerBackground: UIColor { get }

    var headerBackgroundBlue: UIColor { get }
    var headerBackgroundRed: UIColor { get }

    var lightOrange: UIColor { get }

    var captionGray: UIColor { get }
    var cardBackground: UIColor { get }
}

final class ENColors: Colors, Logging {
    var primary: UIColor {
        return color(for: "PrimaryColor")
    }

    var secondaryLight: UIColor {
        return color(for: "SecondaryLight")
    }

    var tertiary: UIColor {
        return color(for: "TertiaryColor")
    }

    var warning: UIColor {
        return color(for: "WarningColor")
    }

    var gray: UIColor {
        return color(for: "GrayColor")
    }

    var ok: UIColor {
        return color(for: "OkGreen")
    }

    var notified: UIColor {
        return color(for: "NotifiedRed")
    }

    var inactive: UIColor {
        return color(for: "InactiveOrange")
    }
    
    var disabled: UIColor {
        return color(for: "Disabled")
    }

    var inactiveGray: UIColor {
        return color(for: "InactiveGray")
    }

    var statusGradientActive: UIColor {
        return color(for: "StatusGradientBlue")
    }

    var statusGradientPaused: UIColor {
        return color(for: "StatusGradientGray")
    }

    var statusGradientNotified: UIColor {
        return color(for: "StatusGradientRed")
    }

    var navigationControllerBackground: UIColor {
        return color(for: "NavigationControllerBackgroundColor")
    }

    var viewControllerBackground: UIColor {
        return color(for: "ViewControllerBackgroundColor")
    }

    var headerBackgroundBlue: UIColor {
        return color(for: "HeaderBackgroundBlue")
    }

    var headerBackgroundRed: UIColor {
        return color(for: "HeaderBackgroundRed")
    }

    var lightOrange: UIColor {
        return color(for: "LightOrange")
    }

    var captionGray: UIColor {
        return color(for: "CaptionGray")
    }

    var cardBackground: UIColor {
        return color(for: "CardBackground")
    }

    // MARK: - Private

    private func color(for name: String) -> UIColor {
        let bundle = Bundle(for: ENColors.self)
        if let color = UIColor(named: name, in: bundle, compatibleWith: nil) {
            return color
        }
        logError("Color: \(name) not found")
        return .clear
    }
}
