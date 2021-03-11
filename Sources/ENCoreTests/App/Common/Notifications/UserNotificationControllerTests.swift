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
            completion(true)
        }
        
        sut = UserNotificationController(userNotificationCenter: mockUserNotificationCenter)
    }
    
    func test_displayUploadFailedNotification_shouldShowNotificationDuringGGDOpeningHours() {
        let date = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        DateTimeTestingOverrides.overriddenCurrentDate = date
        
        sut.displayUploadFailedNotification()
        
        XCTAssertNil(mockUserNotificationCenter.addArgValues.first?.trigger)
    }
    
    func test_displayUploadFailedNotification_shouldScheduleNotificationDuringGGDClosingHours() throws {
        let date = Date(timeIntervalSince1970: 1593311000) // 28/06/20 02:23
        DateTimeTestingOverrides.overriddenCurrentDate = date
        
        sut.displayUploadFailedNotification()
        
        let trigger = try XCTUnwrap(mockUserNotificationCenter.addArgValues.first?.trigger as? UNCalendarNotificationTrigger?)
        
        /// GGD working hours
        XCTAssertEqual(trigger?.dateComponents.hour, 8)
        XCTAssertEqual(trigger?.dateComponents.minute, 0)
        XCTAssertEqual(trigger?.dateComponents.timeZone, TimeZone(identifier: "Europe/Amsterdam"))
    }
}
