/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol ExposureConfiguration {

    // v1 and v2 parameters
    var minimumRiskScore: UInt8 { get }

    // v1 parameters
    var attenuationLevelValues: [UInt8] { get }
    var daysSinceLastExposureLevelValues: [UInt8] { get }
    var durationLevelValues: [UInt8] { get }
    var transmissionRiskLevelValues: [UInt8] { get }
    var attenuationDurationThresholds: [Int] { get }

    // v2 parameters
    var reportTypeWeights: [Double] { get }
    var infectiousnessWeights: [Double] { get }
    var attenuationBucketThresholdDb: [UInt8] { get }
    var attenuationBucketWeights: [Double] { get }
    var daysSinceExposureThreshold: UInt { get }
    var minimumWindowScore: Double { get }
    var daysSinceOnsetToInfectiousness: [UInt8] { get } // [-14, 14]
}
