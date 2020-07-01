/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class OnboardingViewControllerTests: TestCase {
    private var viewController: OnboardingViewController!
    private let router = OnboardingRoutingMock()
    private let listener = OnboardingListenerMock()
    private let consentManager = OnboardingConsentManagingMock()

    override func setUp() {
        super.setUp()

        viewController = OnboardingViewController(onboardingConsentManager: consentManager,
                                                  listener: listener,
                                                  theme: theme)
        viewController.router = router
    }

    // TODO: Add tests
}
