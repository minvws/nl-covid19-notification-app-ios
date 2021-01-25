/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import XCTest

final class PauseControllerTests: TestCase {
    private var sut: PauseController!

    private var mockExposureDataController: ExposureDataControllingMock!
    private var mockExposureController: ExposureControllingMock!
    private var mockUserNotificationCenter: UserNotificationCenterMock!
    private var mockBackgroundController: BackgroundControllingMock!

    override func setUp() {
        super.setUp()

        mockExposureDataController = ExposureDataControllingMock()
        mockExposureController = ExposureControllingMock()
        mockUserNotificationCenter = UserNotificationCenterMock()
        mockBackgroundController = BackgroundControllingMock()

        sut = PauseController(exposureDataController: mockExposureDataController,
                              exposureController: mockExposureController,
                              userNotificationCenter: mockUserNotificationCenter,
                              backgroundController: mockBackgroundController)
    }

    func test_isAppPaused() {
        mockExposureDataController.isAppPaused = true
        XCTAssertTrue(sut.isAppPaused)

        mockExposureDataController.isAppPaused = false
        XCTAssertFalse(sut.isAppPaused)
    }

    func test_pauseTimeElapsed_withNoEndDate() {
        let now = Date()
        DateTimeTestingOverrides.overriddenCurrentDate = now
        mockExposureDataController.pauseEndDate = nil
        XCTAssertTrue(sut.pauseTimeElapsed)
    }

    func test_pauseTimeElapsed_withElapsedPauseEndDate() {
        let now = Date()
        DateTimeTestingOverrides.overriddenCurrentDate = now
        mockExposureDataController.pauseEndDate = now.addingTimeInterval(-1)
        XCTAssertTrue(sut.pauseTimeElapsed)
    }

    func test_pauseTimeElapsed_withPauseEndDateInFuture() {
        let now = Date()
        DateTimeTestingOverrides.overriddenCurrentDate = now
        mockExposureDataController.pauseEndDate = now.addingTimeInterval(1)
        XCTAssertFalse(sut.pauseTimeElapsed)
    }

    func test_getPauseTimeOptionsController() throws {
        let alertController = sut.getPauseTimeOptionsController()

        XCTAssertEqual(alertController.actions[0].title, "1 hour")
        XCTAssertEqual(alertController.actions[1].title, "2 hours")
        XCTAssertEqual(alertController.actions[2].title, "4 hours")
        XCTAssertEqual(alertController.actions[3].title, "8 hours")
        XCTAssertEqual(alertController.actions[4].title, "12 hours")
        XCTAssertEqual(alertController.actions[5].title, "Cancel")
    }

    func test_getPauseTimeOptionsController_alertActionShouldPauseApp() throws {
        let now = Date()
        let expectedPauseEndDate = now.addingTimeInterval(.hours(1))

        DateTimeTestingOverrides.overriddenCurrentDate = now

        let alertController = sut.getPauseTimeOptionsController()

        alertController.tapButton(withTitle: "1 hour")

        XCTAssertEqual(mockExposureController.pauseCallCount, 1)
        XCTAssertEqual(mockExposureController.pauseArgValues.first, expectedPauseEndDate)
        XCTAssertEqual(mockUserNotificationCenter.removeAllPendingNotificationRequestsCallCount, 1)
    }

    func test_unpause() {
        sut.unpauseApp()

        XCTAssertEqual(mockExposureController.unpauseCallCount, 1)
        XCTAssertEqual(mockUserNotificationCenter.removeDeliveredNotificationsCallCount, 1)
        XCTAssertEqual(mockUserNotificationCenter.removeDeliveredNotificationsArgValues.first?.first, PushNotificationIdentifier.pauseEnded.rawValue)
    }

    func test_hidePauseInformationScreen() {
        sut.hidePauseInformationScreen()

        XCTAssertEqual(mockExposureDataController.hidePauseInformationSetCallCount, 1)
        XCTAssertEqual(mockExposureDataController.hidePauseInformation, true)
    }

    func test_getPauseCountdownString_pauseTimeElapsed() {
        let now = Date()
        DateTimeTestingOverrides.overriddenCurrentDate = now

        let countdownString = PauseController.getPauseCountdownString(theme: theme, endDate: now.addingTimeInterval(-1), center: false, emphasizeTime: false)

        XCTAssertEqual(countdownString.string, "The app is not active yet. You need to turn it on again yourself.")
    }

    func test_getPauseCountdownString_pauseEndTimeWithinAMinute() {
        let now = Date()
        DateTimeTestingOverrides.overriddenCurrentDate = now

        let countdownString = PauseController.getPauseCountdownString(theme: theme, endDate: now.addingTimeInterval(1), center: false, emphasizeTime: false)

        XCTAssertEqual(countdownString.string, "The app will be turned on again in 1 minute")
    }

    func test_getPauseCountdownString_pauseEndTimeWithin2hours() {
        let now = Date()
        DateTimeTestingOverrides.overriddenCurrentDate = now

        let countdownString = PauseController.getPauseCountdownString(theme: theme, endDate: now.addingTimeInterval(.hours(1.5)), center: false, emphasizeTime: false)

        XCTAssertEqual(countdownString.string, "The app will be turned on again in 1 hour, 30 minutes")
    }
}

private extension UIAlertController {
    typealias AlertHandler = @convention(block) (UIAlertAction) -> ()

    func tapButton(withTitle title: String) {
        guard let action = actions.first(where: { $0.title == title }), let block = action.value(forKey: "handler") else { return }
        let handler = unsafeBitCast(block as AnyObject, to: AlertHandler.self)
        handler(action)
    }
}
