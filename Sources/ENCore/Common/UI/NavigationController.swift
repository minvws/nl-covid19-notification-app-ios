/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class NavigationController: UINavigationController, ViewControllable, Themeable {

    // MARK: - ViewControllable

    var uiviewController: UIViewController { return self }

    let theme: Theme

    // MARK: - Init

    init(theme: Theme) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    init(rootViewController: UIViewController, theme: Theme) {
        self.theme = theme
        super.init(rootViewController: rootViewController)
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.theme = ENTheme() // Default to ENTheme
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable, message: "NSCoder and Interface Builder is not supported. Use Programmatic layout.")
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Not Supported")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = theme.colors.navigationControllerBackground
    }
}
