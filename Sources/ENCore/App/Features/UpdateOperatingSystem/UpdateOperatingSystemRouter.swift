/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol UpdateOperatingSystemViewControllable: ViewControllable {
    var router: LaunchScreenRouting? { get set }
}

final class UpdateOperatingSystemRouter: Router<UpdateOperatingSystemViewControllable>, LaunchScreenRouting {
    override init(viewController: UpdateOperatingSystemViewControllable) {
        super.init(viewController: viewController)
        viewController.router = self
    }
}
