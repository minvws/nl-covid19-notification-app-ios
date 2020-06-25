/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol ExposureConfiguration {
    var minimumRiskScope: UInt8 { get }
    var attenuationLevelValues: [Int] { get }
    var daysSinceLastExposureLevelValues: [Int] { get }
    var durationLevelValues: [Int] { get }
    var transmissionRiskLevelValues: [Int] { get }
    var attenuationDurationThresholds: [Int] { get }
}
