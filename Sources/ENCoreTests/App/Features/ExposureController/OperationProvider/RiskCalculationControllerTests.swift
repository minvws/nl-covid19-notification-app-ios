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

    func test_getLastExposureDate_riskyScanInstanceShouldReturnLastDate() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 200)
        let newWindowDate = Date()
        let oldWindowDate = newWindowDate.addingTimeInterval(.days(-3)) // some date in the past
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: newWindowDate, diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 50, typicalAttenuation: 50, secondsSinceLastScan: 300)
            ]),
            ExposureWindowMock(calibrationConfidence: .high, date: oldWindowDate, diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 50, typicalAttenuation: 50, secondsSinceLastScan: 300)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertEqual(exposureDate, newWindowDate)
    }

    func test_getLastExposureDate_highestAttenuationShouldNotReturnDate() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 200)
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: Date(), diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 100, typicalAttenuation: 100, secondsSinceLastScan: 300)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertNil(exposureDate)
    }

    func test_getLastExposureDate_summedScoreOverMinimumScoreShouldReturnDate() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 500)
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
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 800)
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock(calibrationConfidence: .high, date: Date(), diagnosisReportType: .confirmedTest, infectiousness: .high, scans: [
                ScanInstanceMock(minimumAttenuation: 50, typicalAttenuation: 50, secondsSinceLastScan: 300),
                ScanInstanceMock(minimumAttenuation: 50, typicalAttenuation: 50, secondsSinceLastScan: 300)
            ])
        ]

        let exposureDate = sut.getLastExposureDate(fromWindows: exposureWindows, withConfiguration: configuration)

        XCTAssertNil(exposureDate)
    }

    func test_getLastExposureDate_attenuationMultiplierShouldCauseExposure_forImmediateAttenuation() {
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 300, attenuationBucketWeights: [1.5, 1.0, 1.0, 1.0])
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
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 300, attenuationBucketWeights: [1.0, 1.5, 1.0, 1.0])
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
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 300, attenuationBucketWeights: [1.0, 1.0, 1.5, 1.0])
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
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 300, reportTypeWeights: [0.0, 1.5, 0.0, 0.0, 0.0, 0.0])
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
        let configuration = getMockExposureRiskConfiguration(minimumRiskScore: 300, infectiousnessWeights: [0.0, 0.0, 1.5])
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
        reportTypeWeights: [Double] = [0.0, 1.0, 1.0, 0.0, 0.0, 0.0],
        infectiousnessWeights: [Double] = [0.0, 1.0, 1.0],
        attenuationBucketWeights: [Double] = [1.0, 1.0, 1.0, 0.0]
    ) -> ExposureRiskConfiguration {

        ExposureRiskConfiguration(
            identifier: "identifier",
            minimumRiskScore: minimumRiskScore,
            reportTypeWeights: reportTypeWeights,
            reportTypeWhenMissing: 1,
            infectiousnessWeights: infectiousnessWeights,
            attenuationBucketThresholdDb: [50, 60, 70],
            attenuationBucketWeights: attenuationBucketWeights,
            daysSinceExposureThreshold: 10,
            minimumWindowScore: 0,
            daysSinceOnsetToInfectiousness: [
                .init(daysSinceOnsetOfSymptoms: -14, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -13, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -12, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -11, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -10, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -9, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -8, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -7, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -6, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -5, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -4, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -3, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -2, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -1, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 0, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 1, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 2, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 3, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 4, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 5, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 6, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 7, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 8, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 9, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 10, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 11, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 12, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 13, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 14, infectiousness: 1)
            ],
            infectiousnessWhenDaysSinceOnsetMissing: 1
        )
    }
}
