/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

public protocol Theme: AnyObject {
    var fonts: Fonts { get }
    var colors: Colors { get }
    var animationsSupported: Bool { get }
    var darkModeEnabled: Bool { get }

    func appearanceAdjustedAnimationName(_ name: String) -> String
    
    init()
}

public typealias ThemeColor = KeyPath<Colors, UIColor>

public protocol Themeable {
    var theme: Theme { get }
}

public protocol ReusableThemable: Themeable {
    func configure(with theme: Theme)
}

public final class ENTheme: Theme {
    public let fonts: Fonts
    public let colors: Colors
    public let animationsSupported: Bool
    public let darkModeEnabled: Bool

    public init() {

        func animationsSupported() -> Bool {
            if #available(iOS 13, *) {
                return true
            }
            return false
        }

        self.fonts = ENFonts()
        self.colors = ENColors()
        self.animationsSupported = animationsSupported()
        
        func darkModeEnabled() -> Bool {
            if #available(iOS 13.0, *) {
                return UIScreen.main.traitCollection.userInterfaceStyle == .dark
            }
            return false
        }
        
        self.darkModeEnabled = darkModeEnabled()
    }
    
    public func appearanceAdjustedAnimationName(_ name: String) -> String {
        return darkModeEnabled ? "darkmode_\(name)" : name
    }
}
