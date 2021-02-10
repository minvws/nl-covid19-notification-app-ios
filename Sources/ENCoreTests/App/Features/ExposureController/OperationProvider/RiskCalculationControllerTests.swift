/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

class RiskCalculationControllerTests: XCTestCase {

    private var sut: RiskCalculationController!

    override func setUpWithError() throws {
        sut = RiskCalculationController()
    }

    // MARK: - Tests

    func test_getLastExposureDate_noExposureWindowsShouldReturnNoDate() {
        let configuration = getMockExposureRiskConfiguration()
        let exposureWindows: [ExposureWindow] = []

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertNil(exposureDate)
    }

    func test_getLastExposureDate_windowWithoutScanInstancesShouldReturnNoDate() {
        let configuration = getMockExposureRiskConfiguration()
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: Date(), diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertNil(exposureDate)
    }

    // MARK: - Private Helpers

    private func getMockExposureRiskConfiguration(minimumRiskScore: UInt8 = 200) -> ExposureRiskConfiguration {
        ExposureRiskConfiguration(
            identifier: "identifier",
            minimumRiskScore: minimumRiskScore,
            attenuationLevelValues: [56, 62, 70],
            daysSinceLastExposureLevelValues: [1, 1, 1, 1, 1, 1, 1, 1],
            durationLevelValues: [0, 0, 0, 1, 2, 2, 2, 2],
            transmissionRiskLevelValues: [0, 2, 2, 2, 0, 0, 0, 0],
            attenuationDurationThresholds: [63, 73],
            reportTypeWeights: [0.0, 1.0, 1.0, 0.0, 0.0, 0.0],
            infectiousnessWeights: [0.0, 1.0, 2.0],
            attenuationBucketThresholdDb: [56, 62, 70],
            attenuationBucketWeights: [1.0, 1.0, 0.3, 0.0],
            daysSinceExposureThreshold: 10,
            minimumWindowScore: 0,
            daysSinceOnsetToInfectiousness: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        )
    }
}
