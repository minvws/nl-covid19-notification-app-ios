/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

extension UIViewController {

    func hideNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func hideNavigationBarBackTitle() {
        navigationController?.navigationBar.backItem?.title = ""
    }

    func showNavigationBarBackTitle() {
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: localized("back"),
            style: .plain,
            target: nil,
            action: nil
        )
    }

    func showNavigationBar(animated showAnimated: Bool = false) {
        navigationController?.setNavigationBarHidden(false, animated: showAnimated)
    }

    func setThemeNavigationBar(withTitle title: String = "",
                               backgroundColor: UIColor = .viewControllerBackgroundColor,
                               shouldHideBackTitle: Bool = false) {

        navigationController?.navigationBar.topItem?.title = title

        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = backgroundColor
        navigationController?.navigationBar.tintColor = .primaryColor
        navigationController?.navigationBar.shadowImage = UIImage()

        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .regular),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]

        shouldHideBackTitle ? hideNavigationBarBackTitle() : showNavigationBarBackTitle()
    }
}
