/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol ExposureConfiguration {
    var minimumRiskScope: UInt8 { get }
    var attenuationLevelValues: [UInt8] { get }
    var daysSinceLastExposureLevelValues: [UInt8] { get }
    var durationLevelValues: [UInt8] { get }
    var transmissionRiskLevelValues: [UInt8] { get }
    var attenuationDurationThresholds: [Int] { get }
}
