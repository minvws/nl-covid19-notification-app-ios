/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol LaunchScreenViewControllable: ViewControllable {
    var router: LaunchScreenRouting? { get set }
}

final class LaunchScreenRouter: Router<LaunchScreenViewControllable>, LaunchScreenRouting {
    override init(viewController: LaunchScreenViewControllable) {
        super.init(viewController: viewController)
        viewController.router = self
    }
}
