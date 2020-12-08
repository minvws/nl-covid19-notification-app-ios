/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol ExposureDetectionSummary {
    var attenuationDurations: [NSNumber] { get }
    var daysSinceLastExposure: Int { get }
    var matchedKeyCount: UInt64 { get }
    var maximumRiskScore: UInt8 { get }
    var metadata: [AnyHashable: Any]? { get }
}
