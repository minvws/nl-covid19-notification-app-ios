/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

open class ViewController: UIViewController, ViewControllable, Themeable {

    var uiviewController: UIViewController {
        return self
    }

    public let theme: Theme

    // MARK: - Init

    public init(theme: Theme) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable, message: "NSCoder and Interface Builder is not supported. Use Programmatic layout.")
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = theme.colors.viewControllerBackground
        edgesForExtendedLayout = []
    }

    // MARK: - Utility

    class func deviceHasHomeButton() -> Bool {
        var key: UIWindow? {
            if #available(iOS 13, *) {
                return UIApplication.shared.windows.first { $0.isKeyWindow }
            } else {
                return UIApplication.shared.keyWindow
            }
        }
        return key?.safeAreaInsets.bottom ?? 0 == CGFloat(0)
    }
}
