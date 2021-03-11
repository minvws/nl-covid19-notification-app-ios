/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import RxSwift
import SnapshotTesting
import XCTest

final class OnboardingConsentViewControllerTests: TestCase {
    private var viewController: OnboardingConsentStepViewController!
    private let listener = OnboardingConsentListenerMock()
    private let exposureStateStream = ExposureStateStreamingMock()
    private let exposureController = ExposureControllingMock()
    private var manager: OnboardingConsentManager!
    private var interfaceOrientationStream = InterfaceOrientationStreamingMock()
    private var mockUserNotificationCenter = UserNotificationCenterMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        interfaceOrientationStream.isLandscape = BehaviorSubject(value: false)
        interfaceOrientationStream.currentOrientationIsLandscape = false

        manager = OnboardingConsentManager(exposureStateStream: exposureStateStream,
                                           exposureController: exposureController,
                                           userNotificationCenter: mockUserNotificationCenter,
                                           theme: theme)

        AnimationTestingOverrides.animationsEnabled = false
    }

    // MARK: - Tests

    func test_snapshot_onboardingConsentViewController() {
        for (index, _) in manager.onboardingConsentSteps.enumerated() {
            let viewController = OnboardingConsentStepViewController(onboardingConsentManager: manager,
                                                                     listener: listener,
                                                                     theme: theme,
                                                                     index: index,
                                                                     interfaceOrientationStream: interfaceOrientationStream)

            snapshots(matching: viewController, named: "\(#function)\(index)")
        }
    }

    func test_didCompleteConsent() {

        manager.didCompleteConsent()

        XCTAssertEqual(exposureController.didCompleteOnboardingSetCallCount, 1)
    }
}
