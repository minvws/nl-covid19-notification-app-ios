/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

extension UIColor {

    // MARK: - Colors

    class var primaryColor: UIColor { return UIColor(named: "PrimaryColor") ?? .clear }
    class var secondaryColor: UIColor { return UIColor(named: "SecondaryColor") ?? .clear }
    class var tertiaryColor: UIColor { return UIColor(named: "TertiaryColor") ?? .clear }

    class var grayColor: UIColor { return UIColor(named: "GrayColor") ?? .clear }

    class var okGreen: UIColor { return UIColor(named: "OkGreen") ?? .clear }
    class var notifiedRed: UIColor { return UIColor(named: "NotifiedRed") ?? .clear }

    class var statusGradientBlue: UIColor { return UIColor(named: "StatusGradientBlue") ?? .clear }
    class var statusGradientRed: UIColor { return UIColor(named: "StatusGradientRed") ?? .clear }

    // MARK: - Controllers
    
    class var navigationControllerBackgroundColor: UIColor { return UIColor(named: "NavigationControllerBackgroundColor") ?? .clear }
    class var viewControllerBackgroundColor: UIColor { return UIColor(named: "ViewControllerBackgroundColor") ?? .clear }
}
