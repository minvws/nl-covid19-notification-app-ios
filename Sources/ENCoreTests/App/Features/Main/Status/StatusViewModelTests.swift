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

final class StatusViewModelTests: TestCase {

    private let baseDate = Date(timeIntervalSince1970: 1597406400) // 14/08/20 14:00

    func testTimeAgoWithLessThan24hours() {
        DateTimeTestingOverrides.overriddenCurrentDate = baseDate

        let dayBeforeWithLessThan24HoursDifference = Date(timeIntervalSince1970: 1597334400) // 13/08/20 18:00

        let daysBetweenDates = StatusViewModel.timeAgo(from: dayBeforeWithLessThan24HoursDifference)

        XCTAssertEqual(daysBetweenDates, .statusNotifiedDescription(.statusNotifiedDaysAgoOne("1"), two: "Thursday, August 13, 2020"))
    }

    func testTimeAgoWithSameDay() {
        DateTimeTestingOverrides.overriddenCurrentDate = baseDate

        let sameDayDate = Date(timeIntervalSince1970: 1597395600) // 14/08/20 11:00

        let daysBetweenDates = StatusViewModel.timeAgo(from: sameDayDate)

        XCTAssertEqual(daysBetweenDates, .statusNotifiedDescription(.statusNotifiedDaysAgoOne("0"), two: "Friday, August 14, 2020"))
    }

    func testTimeAgoWithMultipleDays() {
        DateTimeTestingOverrides.overriddenCurrentDate = baseDate

        let threeDaysBefore = Date(timeIntervalSince1970: 1597154400) // 11/08/20 16:00

        let daysBetweenDates = StatusViewModel.timeAgo(from: threeDaysBefore)

        XCTAssertEqual(daysBetweenDates, .statusNotifiedDescription(.statusNotifiedDaysAgoOther("3"), two: "Tuesday, August 11, 2020"))
    }
}
