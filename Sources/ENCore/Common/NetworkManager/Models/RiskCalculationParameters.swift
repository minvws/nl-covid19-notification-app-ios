/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

struct RiskCalculationParameters: Codable {
    let minimumRiskScore: Double
    let attenuationScores: [UInt8]
    let daysSinceLastExposureScores: [UInt8]
    let durationScores: [UInt8]
    let transmissionRiskScores: [UInt8]
    let durationAtAttenuationThresholds: [Int]

    let scoreType: Int?
    let reportTypeWeights: [Double]?
    let infectiousnessWeights: [Double]?
    let attenuationBucketThresholdDb: [UInt8]?
    let attenuationBucketWeights: [Double]?
    let daysSinceExposureThreshold: UInt?
    let minimumWindowScore: Double?
    let daysSinceOnsetToInfectiousness: [UInt8]?
}
