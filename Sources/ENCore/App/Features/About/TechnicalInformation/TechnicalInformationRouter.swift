/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

/// @mockable
protocol TechnicalInformationViewControllable: ViewControllable {
    var router: TechnicalInformationRouting? { get set }
}

final class TechnicalInformationRouter: Router<TechnicalInformationViewControllable>, TechnicalInformationRouting {

    init(viewController: TechnicalInformationViewControllable,
         applicationController: ApplicationControlling) {
        self.applicationController = applicationController
        super.init(viewController: viewController)
        viewController.router = self
    }

    func routeToGithubPage() {
        if let url = URL(string: .githubLink) {
            applicationController.open(url)
        }
    }

    private let applicationController: ApplicationControlling
}
