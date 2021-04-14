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
    private var mockUserNotificationController: UserNotificationControllingMock!
    private var mockBackgroundController: BackgroundControllingMock!

    override func setUp() {
        super.setUp()

        mockExposureDataController = ExposureDataControllingMock()
        mockExposureController = ExposureControllingMock()
        mockUserNotificationController = UserNotificationControllingMock()
        mockBackgroundController = BackgroundControllingMock()

        sut = PauseController(exposureDataController: mockExposureDataController,
                              exposureController: mockExposureController,
                              userNotificationController: mockUserNotificationController,
                              backgroundController: mockBackgroundController)
    }

    func test_isAppPaused() {
        mockExposureDataController.isAppPaused = true
        XCTAssertTrue(sut.isAppPaused)

        mockExposureDataController.isAppPaused = false
        XCTAssertFalse(sut.isAppPaused)
    }

    func test_pauseTimeElapsed_withNoEndDate() {
        mockExposureDataController.pauseEndDate = nil
        XCTAssertTrue(sut.pauseTimeElapsed)
    }

    func test_pauseTimeElapsed_withElapsedPauseEndDate() {
        mockExposureDataController.pauseEndDate = currentDate().addingTimeInterval(-1)
        XCTAssertTrue(sut.pauseTimeElapsed)
    }

    func test_pauseTimeElapsed_withPauseEndDateInFuture() {
        mockExposureDataController.pauseEndDate = currentDate().addingTimeInterval(1)
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
        let expectedPauseEndDate = currentDate().addingTimeInterval(.hours(1))

        let alertController = sut.getPauseTimeOptionsController()

        alertController.tapButton(withTitle: "1 hour")

        XCTAssertEqual(mockExposureController.pauseCallCount, 1)
        XCTAssertEqual(mockExposureController.pauseArgValues.first, expectedPauseEndDate)
        XCTAssertEqual(mockUserNotificationController.removeAllPendingNotificationRequestsCallCount, 1)
    }

    func test_unpause() {
        sut.unpauseApp()

        XCTAssertEqual(mockExposureController.unpauseCallCount, 1)
        XCTAssertEqual(mockUserNotificationController.removeDeliveredNotificationsCallCount, 1)
        XCTAssertEqual(mockUserNotificationController.removeDeliveredNotificationsArgValues.first?.first, PushNotificationIdentifier.pauseEnded.rawValue)
        XCTAssertEqual(mockUserNotificationController.removeDeliveredNotificationsArgValues.first?.count, 1)

        XCTAssertEqual(mockUserNotificationController.removePendingNotificationRequestsCallCount, 1)
        XCTAssertEqual(mockUserNotificationController.removePendingNotificationRequestsArgValues.first?.first, PushNotificationIdentifier.pauseEnded.rawValue)
        XCTAssertEqual(mockUserNotificationController.removePendingNotificationRequestsArgValues.first?.count, 1)
    }

    func test_hidePauseInformationScreen() {
        sut.hidePauseInformationScreen()

        XCTAssertEqual(mockExposureDataController.hidePauseInformationSetCallCount, 1)
        XCTAssertEqual(mockExposureDataController.hidePauseInformation, true)
    }

    func test_getPauseCountdownString_pauseTimeElapsed() {
        let countdownString = PauseController.getPauseCountdownString(theme: theme, endDate: currentDate().addingTimeInterval(-1), center: false, emphasizeTime: false)

        XCTAssertEqual(countdownString.string, "CoronaMelder is not active yet. You need to turn it on yourself.")
    }

    func test_getPauseCountdownString_pauseEndTimeWithinAMinute() {
        let countdownString = PauseController.getPauseCountdownString(theme: theme, endDate: currentDate().addingTimeInterval(1), center: false, emphasizeTime: false)

        XCTAssertEqual(countdownString.string, "You'll get a notification in 1 minute to turn on the app again.")
    }

    func test_getPauseCountdownString_shouldRoundUp() {
        let countdownString = PauseController.getPauseCountdownString(theme: theme, endDate: currentDate().addingTimeInterval(91), center: false, emphasizeTime: false)

        XCTAssertEqual(countdownString.string, "You'll get a notification in 2 minutes to turn on the app again.")
    }

    func test_getPauseCountdownString_pauseEndTimeWithin2hours() {
        let countdownString = PauseController.getPauseCountdownString(theme: theme, endDate: currentDate().addingTimeInterval(.hours(1.5)), center: false, emphasizeTime: false)

        XCTAssertEqual(countdownString.string, "You'll get a notification in 1 hour, 30 minutes to turn on the app again.")
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
