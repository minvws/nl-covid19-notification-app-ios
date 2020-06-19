/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class OnboardingStepViewControllerTests: XCTestCase {
    private var viewController: OnboardingStepViewController!
    private let manager = OnboardingManagingMock()
    private let stepBuilder = OnboardingStepBuildableMock()
    private let listener = OnboardingStepListenerMock()

    override func setUp() {
        super.setUp()

        let theme = ENTheme()

        manager.getStepHandler = { index in
            return OnboardingStep(theme: theme,
                                  title: "Title",
                                  content: "Content",
                                  image: UIImage(),
                                  buttonTitle: "Button",
                                  isExample: true)
        }

        viewController = OnboardingStepViewController(onboardingManager: manager,
                                                      onboardingStepBuilder: stepBuilder,
                                                      listener: listener,
                                                      theme: theme,
                                                      index: 0)
    }

    // TODO: Write test cases
    func test_case() {}
}
