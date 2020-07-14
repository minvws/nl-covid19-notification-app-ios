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
    private let stepBuilder = OnboardingStepBuildableMock()
    private let listener = OnboardingStepListenerMock()

    private var manager: OnboardingManager!

    override func setUp() {
        super.setUp()

        recordSnapshots = false
        manager = OnboardingManager(theme: theme)

        AnimationTestingOverrides.animationsEnabled = false
    }

    // MARK: - Tests

    func test_snapshot_onboardingStepViewController() {
        for (index, _) in manager.onboardingSteps.enumerated() {
            let viewController = OnboardingStepViewController(onboardingManager: manager,
                                                              onboardingStepBuilder: stepBuilder,
                                                              listener: listener,
                                                              theme: theme,
                                                              index: index)
            assertSnapshot(matching: viewController, as: .image(), named: "\(#function)\(index)")
        }
    }
}
