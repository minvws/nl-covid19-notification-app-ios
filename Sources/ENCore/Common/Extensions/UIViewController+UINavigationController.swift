/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

extension ViewControllable where Self: ViewController {

    func hideNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func hideNavigationBarBackTitle() {
        navigationController?.navigationBar.backItem?.title = ""
    }

    func showNavigationBarBackTitle() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: .back, style: .plain, target: nil, action: nil)
    }

    func setNavigationRightBarButtonItems(_ items: [UIBarButtonItem]) {
        navigationItem.setRightBarButtonItems(items, animated: false)
    }

    func showNavigationBar(animated showAnimated: Bool = false) {
        navigationController?.setNavigationBarHidden(false, animated: showAnimated)
    }

    func setThemeNavigationBar(withTitle title: String = "", shouldHideBackTitle: Bool = false) {
        guard let navigationBar = navigationController?.navigationBar else {
            return
        }

        navigationBar.topItem?.title = title
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = theme.colors.navigationControllerBackground
        navigationBar.tintColor = theme.colors.primary
        navigationBar.shadowImage = UIImage()
        navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .regular),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]

        shouldHideBackTitle ? hideNavigationBarBackTitle() : showNavigationBarBackTitle()
    }
}
