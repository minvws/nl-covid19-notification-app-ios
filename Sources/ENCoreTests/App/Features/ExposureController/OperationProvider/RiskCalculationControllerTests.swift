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

    func test_getLastExposureDate_noExposureWindowsShouldNotReturnDate() {
        let configuration = getMockExposureRiskConfiguration()
        let exposureWindows: [ExposureWindow] = []

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertNil(exposureDate)
    }

    func test_getLastExposureDate_windowWithoutScanInstancesShouldNotReturnDate() {
        let configuration = getMockExposureRiskConfiguration()
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: Date(), diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertNil(exposureDate)
    }

    func test_getLastExposureDate_riskyScanInstanceShouldReturnDate() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 200)
        let scanInstanceDate = Date()
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: scanInstanceDate, diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 50, typicalAttenuation: 50, secondsSinceLastScan: 300)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertEqual(exposureDate, scanInstanceDate)
    }

    func test_getLastExposureDate_lowAttenuationShouldNotReturnDate() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 200)
        let scanInstanceDate = Date()
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: scanInstanceDate, diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 10, typicalAttenuation: 10, secondsSinceLastScan: 300)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertNil(exposureDate)
    }

    func test_getLastExposureDate_summedScoreOverMinimumScoreShouldReturnDate() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 500, scoreType: .sum)
        let scanInstanceDate = Date()
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: scanInstanceDate, diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 50, typicalAttenuation: 50, secondsSinceLastScan: 300),
                ScanInstanceMock(minimumAttenuation: 50, typicalAttenuation: 50, secondsSinceLastScan: 300)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertEqual(exposureDate, scanInstanceDate)
    }

    func test_getLastExposureDate_summedScoreBelowMinimumScoreShouldNotReturnDate() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 800, scoreType: .sum)
        let scanInstanceDate = Date()
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: scanInstanceDate, diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 50, typicalAttenuation: 50, secondsSinceLastScan: 300),
                ScanInstanceMock(minimumAttenuation: 50, typicalAttenuation: 50, secondsSinceLastScan: 300)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertNil(exposureDate)
    }

    func test_getLastExposureDate_attenuationMultiplierShouldCauseExposure_forImmediateAttenuation() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 300, scoreType: .sum, attenuationBucketWeights: [1.5, 1.0, 1.0, 1.0])
        let scanInstanceDate = Date()
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: scanInstanceDate, diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 50, typicalAttenuation: 50, secondsSinceLastScan: 250)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertEqual(exposureDate, scanInstanceDate)
    }

    func test_getLastExposureDate_attenuationMultiplierShouldCauseExposure_forNearAttenuation() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 300, scoreType: .sum, attenuationBucketWeights: [1.0, 1.5, 1.0, 1.0])
        let scanInstanceDate = Date()
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: scanInstanceDate, diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 60, typicalAttenuation: 60, secondsSinceLastScan: 250)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertEqual(exposureDate, scanInstanceDate)
    }

    func test_getLastExposureDate_attenuationMultiplierShouldCauseExposure_forMediumAttenuation() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 300, scoreType: .sum, attenuationBucketWeights: [1.0, 1.0, 1.5, 1.0])
        let scanInstanceDate = Date()
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: scanInstanceDate, diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 70, typicalAttenuation: 70, secondsSinceLastScan: 250)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertEqual(exposureDate, scanInstanceDate)
    }

    func test_getLastExposureDate_reportTypeMultiplierShouldCauseExposure_forConfirmedTest() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 300, scoreType: .sum, reportTypeWeights: [0.0, 1.5, 0.0, 0.0, 0.0, 0.0])
        let scanInstanceDate = Date()
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: scanInstanceDate, diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 70, typicalAttenuation: 70, secondsSinceLastScan: 250)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertEqual(exposureDate, scanInstanceDate)
    }

    func test_getLastExposureDate_infectiousnessMultiplierShouldCauseExposure_forConfirmedTest() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 300, scoreType: .sum, infectiousnessWeights: [0.0, 0.0, 1.5])
        let scanInstanceDate = Date()
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: scanInstanceDate, diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 70, typicalAttenuation: 70, secondsSinceLastScan: 250)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertEqual(exposureDate, scanInstanceDate)
    }

    // MARK: - Private Helpers

    private func getMockExposureRiskConfiguration(
        minimumRiskScore: Double = 200,
        scoreType: WindowScoreType = .max,
        reportTypeWeights: [Double] = [0.0, 1.0, 1.0, 0.0, 0.0, 0.0],
        infectiousnessWeights: [Double] = [0.0, 1.0, 1.0],
        attenuationBucketWeights: [Double] = [1.0, 1.0, 1.0, 1.0]
    ) -> ExposureRiskConfiguration {

        ExposureRiskConfiguration(
            identifier: "identifier",
            minimumRiskScore: minimumRiskScore,
            attenuationLevelValues: [50, 60, 70],
            daysSinceLastExposureLevelValues: [1, 1, 1, 1, 1, 1, 1, 1],
            durationLevelValues: [0, 0, 0, 1, 2, 2, 2, 2],
            transmissionRiskLevelValues: [0, 2, 2, 2, 0, 0, 0, 0],
            attenuationDurationThresholds: [63, 73],

            // v2
            scoreType: scoreType.rawValue,
            reportTypeWeights: reportTypeWeights,
            infectiousnessWeights: infectiousnessWeights,
            attenuationBucketThresholdDb: [50, 60, 70],
            attenuationBucketWeights: attenuationBucketWeights,
            daysSinceExposureThreshold: 10,
            minimumWindowScore: 0,
            daysSinceOnsetToInfectiousness: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        )
    }
}
