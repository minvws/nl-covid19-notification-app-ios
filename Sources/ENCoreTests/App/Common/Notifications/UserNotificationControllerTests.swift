//
//  UserNotificationControllerTests.swift
//  ENCoreTests
//
//  Created by Roel Spruit on 11/03/2021.
//

import XCTest
import ENFoundation
@testable import ENCore

class UserNotificationControllerTests: TestCase {
    
    private var mockUserNotificationCenter: UserNotificationCenterMock!
    private var sut: UserNotificationController!

    override func setUpWithError() throws {
        
        mockUserNotificationCenter = UserNotificationCenterMock()
        mockUserNotificationCenter.getAuthorizationStatusHandler = { completion in
            completion(.authorized)
        }
        
        sut = UserNotificationController(userNotificationCenter: mockUserNotificationCenter)
    }
    
    func test_getIsAuthorized_shouldCallUserNotificationCenter() {
        // Arrange
        XCTAssertEqual(mockUserNotificationCenter.getAuthorizationStatusCallCount, 0)
        
        // Act
        sut.getIsAuthorized { (authorized) in
            XCTAssertTrue(authorized)
        }
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.getAuthorizationStatusCallCount, 1)
    }
    
    func test_getAuthorizationStatus_shouldCallUserNotificationCenter() {
        // Arrange
        mockUserNotificationCenter.getAuthorizationStatusHandler = { completion in
            completion(.denied)
        }
        
        XCTAssertEqual(mockUserNotificationCenter.getAuthorizationStatusCallCount, 0)
        
        // Act
        sut.getAuthorizationStatus { (status) in
            XCTAssertEqual(status, .denied)
        }
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.getAuthorizationStatusCallCount, 1)
    }
    
    func test_requestNotificationPermission_shouldNotRequestAuthorizationIfAlreadyAuthorized() {
        // Arrange
        mockUserNotificationCenter.getAuthorizationStatusHandler = { completion in
            completion(.authorized)
        }
                
        let completionExpectation = expectation(description: "completion")
        
        XCTAssertEqual(mockUserNotificationCenter.getAuthorizationStatusCallCount, 0)
        XCTAssertEqual(mockUserNotificationCenter.requestAuthorizationCallCount, 0)
        
        // Act
        sut.requestNotificationPermission {
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(mockUserNotificationCenter.getAuthorizationStatusCallCount, 1)
        XCTAssertEqual(mockUserNotificationCenter.requestAuthorizationCallCount, 0)
    }
    
    func test_requestNotificationPermission_shouldRequestAuthorizationIfNotYetAuthorized() {
        // Arrange
        mockUserNotificationCenter.getAuthorizationStatusHandler = { completion in
            completion(.notDetermined)
        }
        
        mockUserNotificationCenter.requestAuthorizationHandler = { _, completion in
            completion(true, nil)
        }
        
        let completionExpectation = expectation(description: "completion")
        
        XCTAssertEqual(mockUserNotificationCenter.getAuthorizationStatusCallCount, 0)
        XCTAssertEqual(mockUserNotificationCenter.requestAuthorizationCallCount, 0)
        
        // Act
        sut.requestNotificationPermission {
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(mockUserNotificationCenter.getAuthorizationStatusCallCount, 1)
        XCTAssertEqual(mockUserNotificationCenter.requestAuthorizationCallCount, 1)
    }
    
    func test_removeAllPendingNotificationRequests_shouldCallUserNotificationCenter() {
        // Arrange
        XCTAssertEqual(mockUserNotificationCenter.removeAllPendingNotificationRequestsCallCount, 0)
        
        // Act
        sut.removeAllPendingNotificationRequests()
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.removeAllPendingNotificationRequestsCallCount, 1)
    }
    
    func test_removePendingNotificationRequests_shouldCallUserNotificationCenter() {
        // Arrange
        XCTAssertEqual(mockUserNotificationCenter.removePendingNotificationRequestsCallCount, 0)
        
        // Act
        sut.removePendingNotificationRequests(withIdentifiers: ["identifier"])
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.removePendingNotificationRequestsCallCount, 1)
        XCTAssertEqual(mockUserNotificationCenter.removePendingNotificationRequestsArgValues.first?.count, 1)
        XCTAssertEqual(mockUserNotificationCenter.removePendingNotificationRequestsArgValues.first?[0], "identifier")
    }
    
    func test_removeDeliveredNotifications_shouldCallUserNotificationCenter() {
        // Arrange
        XCTAssertEqual(mockUserNotificationCenter.removeDeliveredNotificationsCallCount, 0)
        
        // Act
        sut.removeDeliveredNotifications(withIdentifiers: ["identifier"])
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.removeDeliveredNotificationsCallCount, 1)
        XCTAssertEqual(mockUserNotificationCenter.removeDeliveredNotificationsArgValues.first?.count, 1)
        XCTAssertEqual(mockUserNotificationCenter.removeDeliveredNotificationsArgValues.first?[0], "identifier")
    }
    
    func test_removeNotificationsFromNotificationsCenter() {
        // Arrange
        XCTAssertEqual(mockUserNotificationCenter.removeDeliveredNotificationsCallCount, 0)
        
        // Act
        sut.removeNotificationsFromNotificationsCenter()
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.removeDeliveredNotificationsCallCount, 1)
        XCTAssertEqual(mockUserNotificationCenter.removeDeliveredNotificationsArgValues.first, [
            "nl.rijksoverheid.en.exposure",
            "nl.rijksoverheid.en.inactive",
            "nl.rijksoverheid.en.statusDisabled",
            "nl.rijksoverheid.en.appUpdateRequired",
            "nl.rijksoverheid.en.pauseended"
        ])
    }
    
    func test_schedulePauseExpirationNotification() throws {
        // Arrange
        let pauseEndDate = DateComponents(calendar: Calendar.current, year: 2020, month: 6, day: 28, hour: 2, minute: 23, second: 00).date!
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 0)
        
        // Act
        sut.schedulePauseExpirationNotification(pauseEndDate: pauseEndDate)
        
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 1)
        let notificationRequest = try XCTUnwrap(mockUserNotificationCenter.addArgValues.first)
        XCTAssertEqual(notificationRequest.content.sound, .default)
        XCTAssertEqual(notificationRequest.content.badge, 0)
        XCTAssertEqual(notificationRequest.content.title, "Turn CoronaMelder on again")
        XCTAssertEqual(notificationRequest.content.body, "The app is not active yet. You need to turn it on in the app itself.")
        
        let trigger = try XCTUnwrap(notificationRequest.trigger as? UNCalendarNotificationTrigger)
        // These components match with pauseEndDate + 30 seconds
        XCTAssertEqual(trigger.dateComponents.hour, 2)
        XCTAssertEqual(trigger.dateComponents.minute, 23)
        XCTAssertEqual(trigger.dateComponents.second, 30)
    }
    
    func test_displayPauseExpirationReminder() throws {
        // Arrange
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 0)
        
        // Act
        sut.displayPauseExpirationReminder(completion: { _ in })
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 1)
        let notificationRequest = try XCTUnwrap(mockUserNotificationCenter.addArgValues.first)
        XCTAssertEqual(notificationRequest.content.sound, .default)
        XCTAssertEqual(notificationRequest.content.badge, 0)
        XCTAssertEqual(notificationRequest.content.title, "Turn CoronaMelder on again")
        XCTAssertEqual(notificationRequest.content.body, "The app is not active yet. You need to turn it on in the app itself.")
        XCTAssertNil(notificationRequest.trigger)
    }
    
    func test_displayNotActiveNotification() throws {
        // Arrange
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 0)
        
        // Act
        sut.displayNotActiveNotification(completion: { _ in })
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 1)
        let notificationRequest = try XCTUnwrap(mockUserNotificationCenter.addArgValues.first)
        XCTAssertEqual(notificationRequest.content.sound, .default)
        XCTAssertEqual(notificationRequest.content.badge, 0)
        XCTAssertEqual(notificationRequest.content.title, "")
        XCTAssertEqual(notificationRequest.content.body, "CoronaMelder is not active at the moment. Check your settings.")
        XCTAssertNil(notificationRequest.trigger)
    }
    
    func test_displayAppUpdateRequiredNotification() throws {
        // Arrange
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 0)
        
        // Act
        sut.displayAppUpdateRequiredNotification(withUpdateMessage: "updateMessage", completion: { _ in })
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 1)
        let notificationRequest = try XCTUnwrap(mockUserNotificationCenter.addArgValues.first)
        XCTAssertEqual(notificationRequest.content.sound, .default)
        XCTAssertEqual(notificationRequest.content.badge, 0)
        XCTAssertEqual(notificationRequest.content.title, "")
        XCTAssertEqual(notificationRequest.content.body, "updateMessage")
        XCTAssertNil(notificationRequest.trigger)
    }
    
    func test_displayExposureNotification() throws {
        
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 0)
        
        // Act
        sut.displayExposureNotification(daysSinceLastExposure: 5, completion: { _ in })
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 1)
        let notificationRequest = try XCTUnwrap(mockUserNotificationCenter.addArgValues.first)
        XCTAssertEqual(notificationRequest.content.sound, .default)
        XCTAssertEqual(notificationRequest.content.badge, 0)
        XCTAssertEqual(notificationRequest.content.title, "")
        XCTAssertEqual(notificationRequest.content.body, "You were near someone who has coronavirus 5 days ago. Read more in the app.")
        XCTAssertNil(notificationRequest.trigger)
    }
    
    func test_displayExposureReminderNotification() throws {
        // Arrange
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 0)
        
        sut.displayExposureReminderNotification(daysSinceLastExposure: 5, completion: { _ in })
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 1)
        let notificationRequest = try XCTUnwrap(mockUserNotificationCenter.addArgValues.first)
        XCTAssertEqual(notificationRequest.content.sound, .default)
        XCTAssertEqual(notificationRequest.content.badge, 0)
        XCTAssertEqual(notificationRequest.content.title, "")
        XCTAssertEqual(notificationRequest.content.body, "Reminder: You were near someone who has coronavirus 5 days ago. Read more in the app.")
        XCTAssertNil(notificationRequest.trigger)
    }
    
    func test_display24HoursNoActivityNotification() throws {
        // Arrange
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 0)
        
        // Act
        sut.display24HoursNoActivityNotification(completion: { _ in })
        
        // Assert
        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 1)
        let notificationRequest = try XCTUnwrap(mockUserNotificationCenter.addArgValues.first)
        XCTAssertEqual(notificationRequest.content.sound, .default)
        XCTAssertEqual(notificationRequest.content.badge, 0)
        XCTAssertEqual(notificationRequest.content.title, "The app is not active")
        XCTAssertEqual(notificationRequest.content.body, "The app wasn't able to check for 24 hours if the people you encountered later turned out to have corona.")
        XCTAssertNil(notificationRequest.trigger)
    }
    
    func test_displayUploadFailedNotification_shouldShowNotificationDuringGGDOpeningHours() {
        // Arrange
        let date = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        DateTimeTestingOverrides.overriddenCurrentDate = date
        
        // Act
        sut.displayUploadFailedNotification()
        
        // Assert
        XCTAssertNil(mockUserNotificationCenter.addArgValues.first?.trigger)
    }
    
    func test_displayUploadFailedNotification_shouldScheduleNotificationDuringGGDClosingHours() throws {
        // Arrange
        let date = Date(timeIntervalSince1970: 1593311000) // 28/06/20 02:23
        DateTimeTestingOverrides.overriddenCurrentDate = date
        
        // Act
        sut.displayUploadFailedNotification()
        
        // Assert
        let trigger = try XCTUnwrap(mockUserNotificationCenter.addArgValues.first?.trigger as? UNCalendarNotificationTrigger?)
        
        /// GGD working hours
        XCTAssertEqual(trigger?.dateComponents.hour, 8)
        XCTAssertEqual(trigger?.dateComponents.minute, 0)
        XCTAssertEqual(trigger?.dateComponents.timeZone, TimeZone(identifier: "Europe/Amsterdam"))
    }
}
