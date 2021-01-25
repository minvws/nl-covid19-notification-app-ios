/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

class UserNotificationCenterTests: TestCase {

    private var sut: UserNotificationCenterMock!

    override func setUpWithError() throws {

        sut = UserNotificationCenterMock()
    }

    func test_removeNotificationsFromNotificationsCenter() throws {
        sut.removeNotificationsFromNotificationsCenter()

        let identifiers = try XCTUnwrap(sut.removeDeliveredNotificationsArgValues.first)
        XCTAssertEqual(identifiers, [
            PushNotificationIdentifier.exposure.rawValue,
            PushNotificationIdentifier.inactive.rawValue,
            PushNotificationIdentifier.enStatusDisabled.rawValue,
            PushNotificationIdentifier.appUpdateRequired.rawValue,
            PushNotificationIdentifier.pauseEnded.rawValue
        ])
    }

    func test_schedulePauseExpirationNotification() throws {
        let date = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28

        sut.schedulePauseExpirationNotification(pauseEndDate: date)

        let request = try XCTUnwrap(sut.addArgValues.first)
        XCTAssertEqual(request.identifier, PushNotificationIdentifier.pauseEnded.rawValue)
        XCTAssertEqual(request.content.title, .notificationAppUnpausedTitle)
        XCTAssertEqual(request.content.body, .notificationManualUnpauseDescription)
        XCTAssertEqual(request.content.sound, UNNotificationSound.default)
        XCTAssertEqual(request.content.badge, 0)

        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        XCTAssertEqual(trigger.nextTriggerDate()?.timeIntervalSince1970, 1611599288)
    }

    func test_displayPauseExpirationReminder() throws {

        sut.displayPauseExpirationReminder {}

        let request = try XCTUnwrap(sut.addArgValues.first)
        XCTAssertEqual(request.identifier, PushNotificationIdentifier.pauseEnded.rawValue)
        XCTAssertEqual(request.content.title, .notificationAppUnpausedTitle)
        XCTAssertEqual(request.content.body, .notificationManualUnpauseDescription)
        XCTAssertEqual(request.content.sound, UNNotificationSound.default)
        XCTAssertEqual(request.content.badge, 0)
    }
}
