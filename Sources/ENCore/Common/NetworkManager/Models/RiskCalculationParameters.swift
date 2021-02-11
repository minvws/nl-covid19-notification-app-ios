/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

struct DayInfectiousness: Codable, Equatable {
    let daysSinceOnsetOfSymptoms: Int
    let infectiousness: Int
}

struct RiskCalculationParameters: Codable {
    let minimumRiskScore: Double
    let scoreType: Int
    let reportTypeWeights: [Double]
    let infectiousnessWeights: [Double]
    let attenuationBucketThresholdDb: [UInt8]
    let attenuationBucketWeights: [Double]
    let daysSinceExposureThreshold: UInt
    let minimumWindowScore: Double
    let daysSinceOnsetToInfectiousness: [DayInfectiousness]
}
