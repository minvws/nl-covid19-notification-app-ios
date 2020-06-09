/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import EN
import Foundation
import XCTest

final class OnboardingViewControllerTests: XCTestCase {
    private var viewController: OnboardingViewController!
    private let router = OnboardingRoutingMock()
    // TODO: Add other dependencies

    override func setUp() {
        super.setUp()

        viewController = OnboardingViewController()
        viewController.router = router
    }

    // TODO: Add tests
}
