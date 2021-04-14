/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol ExposureConfiguration {
    var minimumRiskScore: Double { get }

    /// This list must have 6 elements: UNKNOWN, CONFIRMED_TEST, CONFIRMED_CLINICAL_DIAGNOSIS, SELF_REPORT, RECURSIVE and REVOKED
    var reportTypeWeights: [Double] { get }

    var reportTypeWhenMissing: UInt32 { get }

    /// This list must have 3 elements: NONE, STANDARD and HIGH infectiousness
    var infectiousnessWeights: [Double] { get }

    /// This list must have 3 elements: the immediate, near, and medium thresholds
    var attenuationBucketThresholdDb: [Int] { get }

    /// This list must have 4 elements, corresponding to the weights for the 4 buckets.
    var attenuationBucketWeights: [Double] { get }

    /// Include exposures for only the last X days
    var daysSinceExposureThreshold: Int { get }

    /// Minimum risk score sum to trigger an exposure notification
    var minimumWindowScore: Double { get }

    var daysSinceOnsetToInfectiousness: [DayInfectiousness] { get }

    var infectiousnessWhenDaysSinceOnsetMissing: Int { get }
}
