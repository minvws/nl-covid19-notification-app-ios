/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

public extension UIBarButtonItem {
    static func closeButton(target: Any?, action: Selector) -> UIBarButtonItem {
        if #available(iOS 13.0, *) {
            return UIBarButtonItem(barButtonSystemItem: .close, target: target, action: action)
        } else {
            let button = UIButton(type: .system)
            button.setImage(.closeButton, for: .normal)
            button.frame = CGRect(origin: .zero, size: CGSize(width: 40, height: 40))
            button.addTarget(target, action: action, for: .touchUpInside)
            button.imageView?.translatesAutoresizingMaskIntoConstraints = false
            button.imageView?.widthAnchor.constraint(equalToConstant: 32).isActive = true
            button.imageView?.heightAnchor.constraint(equalToConstant: 32).isActive = true

            let menuBarItem = UIBarButtonItem(customView: button)
            return menuBarItem
        }
    }
}
