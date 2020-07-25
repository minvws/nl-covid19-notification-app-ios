/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

/// @mockable
protocol AboutViewControllable: ViewControllable {
    var router: AboutRouting? { get set }
}

final class AboutRouter: Router<AboutViewControllable>, AboutRouting {

    override init(viewController: AboutViewControllable) {
        super.init(viewController: viewController)
        viewController.router = self
    }
}
