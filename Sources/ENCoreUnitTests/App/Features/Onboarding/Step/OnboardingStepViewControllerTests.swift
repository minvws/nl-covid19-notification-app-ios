/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import SnapshotTesting
import XCTest

final class OnboardingStepViewControllerTests: TestCase {
    private var viewController: OnboardingStepViewController!
    private let manager = OnboardingManagingMock()
    private let stepBuilder = OnboardingStepBuildableMock()
    private let listener = OnboardingStepListenerMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        manager.getStepHandler = { index in
            return OnboardingStep(theme: self.theme,
                                  title: "Title",
                                  content: "Content",
                                  illustration: .image(named: "Step5"),
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
    func test_case() {
        assertSnapshot(matching: viewController, as: .image())
    }
}
