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
    var minimumRiskScore: Double { get }

    // v1 parameters
    var attenuationLevelValues: [UInt8] { get }
    var daysSinceLastExposureLevelValues: [UInt8] { get }
    var durationLevelValues: [UInt8] { get }
    var transmissionRiskLevelValues: [UInt8] { get }
    var attenuationDurationThresholds: [Int] { get }

    // v2 parameters
    var scoreType: Int { get }
    var reportTypeWeights: [Double] { get } //  This list must have 6 elements: UNKNOWN, CONFIRMED_TEST, CONFIRMED_CLINICAL_DIAGNOSIS, SELF_REPORT, RECURSIVE and REVOKED
    var infectiousnessWeights: [Double] { get } // This list must have 3 elements: NONE, STANDARD and HIGH infectiousness
    var attenuationBucketThresholdDb: [UInt8] { get } // This list must have 3 elements: the immediate, near, and medium thresholds
    var attenuationBucketWeights: [Double] { get } // This list must have 4 elements, corresponding to the weights for the 4 buckets.
    var daysSinceExposureThreshold: UInt { get } // Include exposures for only the last X days
    var minimumWindowScore: Double { get } // Minimum risk score sum to trigger an exposure notification
    var daysSinceOnsetToInfectiousness: [UInt8] { get } // [-14, 14]
}
