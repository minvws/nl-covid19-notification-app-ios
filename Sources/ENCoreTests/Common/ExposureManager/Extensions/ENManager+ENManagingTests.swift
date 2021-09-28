/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ExposureNotification
import XCTest

@testable import ENCore

class ENManager_ENManagingTests: TestCase {

    func test_defaultExposureConfiguration_init_fromExposureConfiguration() {
        // Arrange
        let mockConfiguration = ExposureConfigurationMock.testData()

        // Act
        let enExposureConfiguration = mockConfiguration.asExposureConfiguration

        // Assert
        XCTAssertEqual(enExposureConfiguration.minimumRiskScoreFullRange, 1)
        XCTAssertEqual(enExposureConfiguration.immediateDurationWeight, 6)
        XCTAssertEqual(enExposureConfiguration.nearDurationWeight, 7)
        XCTAssertEqual(enExposureConfiguration.mediumDurationWeight, 8)
        XCTAssertEqual(enExposureConfiguration.otherDurationWeight, 9)

        if #available(iOS 14.0, *) {
            XCTAssertEqual(enExposureConfiguration.infectiousnessForDaysSinceOnsetOfSymptoms, [NSNumber(value: ENDaysSinceOnsetOfSymptomsUnknown): 10])
        }

        XCTAssertEqual(enExposureConfiguration.infectiousnessStandardWeight, 5)
        XCTAssertEqual(enExposureConfiguration.infectiousnessHighWeight, 6)

        XCTAssertEqual(enExposureConfiguration.reportTypeConfirmedTestWeight, 4)
        XCTAssertEqual(enExposureConfiguration.reportTypeConfirmedClinicalDiagnosisWeight, 5)
        XCTAssertEqual(enExposureConfiguration.reportTypeSelfReportedWeight, 6)
        XCTAssertEqual(enExposureConfiguration.reportTypeRecursiveWeight, 7)
        XCTAssertEqual(enExposureConfiguration.reportTypeNoneMap.rawValue, 11)

        XCTAssertEqual(enExposureConfiguration.attenuationDurationThresholds, [5])
        XCTAssertEqual(enExposureConfiguration.daysSinceLastExposureThreshold, 7)
    }
}
