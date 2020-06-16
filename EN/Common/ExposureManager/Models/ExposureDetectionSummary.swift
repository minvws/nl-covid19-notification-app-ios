/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct ExposureDetectionSummary {
    let attenuationDurations: [NSNumber]
    let daysSinceLastExposure: Int
    let matchedKeyCount: UInt64
    let maximumRiskScore: UInt8
    let metadata: [AnyHashable: Any]?
}
