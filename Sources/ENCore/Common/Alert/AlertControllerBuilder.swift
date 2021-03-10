//
//  AlertControllerBuilder.swift
//  ENCore
//
//  Created by Roel Spruit on 10/03/2021.
//

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
