/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

/// @mockable
protocol AlertControlling {
    func addAction(_ action: UIAlertAction)
}

extension UIAlertController: AlertControlling {}

/// @mockable(history:buildAlertAction=true)
protocol AlertControllerBuildable {
    func buildAlertController(withTitle title: String?, message: String?, preferredStyle: UIAlertController.Style) -> AlertControlling & UIViewController
    
    func buildAlertAction(title: String?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction
}

class AlertControllerBuilder: AlertControllerBuildable {
    func buildAlertController(withTitle title: String?, message: String?, preferredStyle: UIAlertController.Style) -> AlertControlling & UIViewController {
        return UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
    }
    
    func buildAlertAction(title: String?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return UIAlertAction(title: title, style: style, handler: handler)
    }
}
