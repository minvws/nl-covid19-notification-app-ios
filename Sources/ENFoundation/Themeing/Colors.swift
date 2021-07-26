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

    var textPrimary: UIColor { get }
    var textSecondary: UIColor { get }
    var divider: UIColor { get }
    var textButtonPrimary: UIColor { get }
    var textButtonTertiary: UIColor { get }
    var textDark: UIColor { get }
    var settingsStepBackground: UIColor { get }
    
    var ok: UIColor { get }
    var notified: UIColor { get }
    var inactive: UIColor { get }
    var inactiveGray: UIColor { get }
    var disabled: UIColor { get }

    var statusGradientActiveTop: UIColor { get }
    var statusGradientActiveBottom: UIColor { get }
    var statusGradientNotifiedTop: UIColor { get }
    var statusGradientNotifiedBottom: UIColor { get }
    var statusGradientPausedTop: UIColor { get }
    var statusGradientPausedBottom: UIColor { get }
    var statusGradientInactiveTop: UIColor { get }
    var statusGradientInactiveBottom: UIColor { get }

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

    var textSecondary: UIColor {
        return color(for: "TextSecondary")
    }
    
    var textPrimary: UIColor {
        return color(for: "TextPrimary")
    }
    
    var textButtonPrimary: UIColor {
        return color(for: "TextButtonPrimary")
    }
    
    var textButtonTertiary: UIColor {
        return color(for: "TextButtonTertiary")
    }
    
    var textDark: UIColor {
        return color(for: "TextDark")
    }
    
    var settingsStepBackground: UIColor {
        return color(for: "SettingsStepBackground")
    }
    
    var divider: UIColor {
        return color(for: "Divider")
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

    var statusGradientActiveTop: UIColor {
        return color(for: "StatusGradientActiveTop")
    }
    
    var statusGradientActiveBottom: UIColor {
        return color(for: "StatusGradientActiveBottom")
    }

    var statusGradientPausedTop: UIColor {
        return color(for: "StatusGradientPausedTop")
    }
    
    var statusGradientPausedBottom: UIColor {
        return color(for: "StatusGradientPausedBottom")
    }

    var statusGradientNotifiedTop: UIColor {
        return color(for: "StatusGradientNotifiedTop")
    }
    
    var statusGradientNotifiedBottom: UIColor {
        return color(for: "StatusGradientNotifiedBottom")
    }
    
    var statusGradientInactiveTop: UIColor {
        return color(for: "StatusGradientInactiveTop")
    }
    
    var statusGradientInactiveBottom: UIColor {
        return color(for: "StatusGradientInactiveBottom")
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
