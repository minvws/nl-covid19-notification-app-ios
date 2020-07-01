/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class OnboardingConsentViewControllerTests: TestCase {
    private var viewController: OnboardingConsentStepViewController!
    private let listener = OnboardingConsentListenerMock()
    private let manager = OnboardingConsentManagingMock()

    override func setUp() {
        super.setUp()

        viewController = OnboardingConsentStepViewController(onboardingConsentManager: manager,
                                                             listener: listener,
                                                             theme: theme,
                                                             index: 0)
    }
}
