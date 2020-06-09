/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import EN
import Foundation
import XCTest

final class OnboardingHelpViewControllerTests: XCTestCase {
    private var viewController: OnboardingHelpViewController!
    private let listener = OnboardingHelpListenerMock()

    override func setUp() {
        super.setUp()

        viewController = OnboardingHelpViewController(listener: listener)
    }

    // TODO: Write test cases
    func test_case() {}
}
