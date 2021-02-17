/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct ExposureRiskConfiguration: Codable, ExposureConfiguration, Equatable {
    let identifier: String
    let minimumRiskScore: Double
    let windowCalculationType: Int
    let reportTypeWeights: [Double]
    let reportTypeWhenMissing: UInt32
    let infectiousnessWeights: [Double]
    let attenuationBucketThresholdDb: [Int]
    let attenuationBucketWeights: [Double]
    let daysSinceExposureThreshold: Int
    let minimumWindowScore: Double
    let daysSinceOnsetToInfectiousness: [DayInfectiousness]
    let infectiousnessWhenDaysSinceOnsetMissing: Int
}
