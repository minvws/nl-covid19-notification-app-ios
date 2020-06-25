/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

struct RiskCalculationParameters: Codable {
    let minimumRiskScore: Int
    let attenuationScores: [Int]
    let daysSinceLastExposureScores: [Int]
    let durationScores: [Int]
    let transmissionRiskScores: [Int]
    let durationAtAttenuationThresholds: [Int]
}
