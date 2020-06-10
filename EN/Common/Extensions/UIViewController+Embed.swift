//
//  UIViewController+Embed.swift
//  EN
//
//  Created by Robin van Dijke on 10/06/2020.
//

import Foundation
import UIKit

extension UIViewController {
    func embed(childViewController: UIViewController) {
        addChild(childViewController)
        view.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
    }
}
