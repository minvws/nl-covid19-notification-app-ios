/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class OnboardingConsentManagerTests: TestCase {
    private var sut: OnboardingConsentManager!
    private var mockExposureStateStream: ExposureStateStreamingMock!
    private var mockExposureController: ExposureControllingMock!
    private var mockUserNotificationCenter: UserNotificationCenterMock!

    override func setUp() {
        super.setUp()

        mockExposureStateStream = ExposureStateStreamingMock()
        mockExposureController = ExposureControllingMock()
        mockUserNotificationCenter = UserNotificationCenterMock()

        sut = OnboardingConsentManager(exposureStateStream: mockExposureStateStream,
                                       exposureController: mockExposureController,
                                       userNotificationCenter: mockUserNotificationCenter, theme: theme)
    }

    func test_askNotificationsAuthorization_shouldCallUserNotificationCenter() {
        let completionExpectation = expectation(description: "completion")
        let userNotificationExpectation = expectation(description: "userNotificationExpectation")
        mockUserNotificationCenter.requestNotificationPermissionHandler = { completion in
            userNotificationExpectation.fulfill()
            completion()
        }

        sut.askNotificationsAuthorization {
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockUserNotificationCenter.requestNotificationPermissionCallCount, 1)
    }
}
