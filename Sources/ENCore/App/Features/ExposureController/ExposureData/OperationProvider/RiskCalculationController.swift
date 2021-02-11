/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import ExposureNotification
import Foundation

/// @mockable
protocol RiskCalculationControlling {
    func getLastExposureDate(fromWindows windows: [ExposureWindow], withConfiguration configuration: ExposureConfiguration) -> Date?
}

class RiskCalculationController: RiskCalculationControlling, Logging {

    func getLastExposureDate(fromWindows windows: [ExposureWindow],
                             withConfiguration configuration: ExposureConfiguration) -> Date? {

        guard !windows.isEmpty else {
            return nil
        }

        let dailyScores = getDailyRiskScores(windows: windows, configuration: configuration)

        self.logDebug("V2 Risk Calculation - Daily risk scores: \(windows)")

        let lastDayOverMinimumRiskScore = dailyScores
            .filter { $0.value >= Double(configuration.minimumRiskScore) }
            .map { $0.key }
            .sorted()
            .last

        if let exposureDate = lastDayOverMinimumRiskScore {
            self.logDebug("V2 Risk Calculation - Latest day over minimum risk score: \(exposureDate)")
        } else {
            self.logDebug("V2 Risk Calculation - No date found with riskscore over minimumRiskScore(\(configuration.minimumRiskScore)")
        }

        return lastDayOverMinimumRiskScore
    }

    // Gets the daily list of risk scores from the given exposure windows.
    private func getDailyRiskScores(windows: [ExposureWindow],
                                    configuration: ExposureConfiguration) -> [Date: Double] {

        guard let scoreType = WindowScoreType(rawValue: configuration.scoreType) else {
            return [:]
        }

        var perDayScore = [Date: Double]()
        windows.forEach { window in

            let windowScore = self.getWindowScore(window: window, configuration: configuration)

            if windowScore >= configuration.minimumWindowScore {
                switch scoreType {
                case WindowScoreType.max:
                    perDayScore[window.date] = max(perDayScore[window.date] ?? 0.0, windowScore)
                case WindowScoreType.sum:
                    perDayScore[window.date] = perDayScore[window.date] ?? 0.0 + windowScore
                }
            }
        }

        return perDayScore
    }

    // Computes the risk score associated with a single window based on the exposure seconds, attenuation, and report type.
    private func getWindowScore(window: ExposureWindow,
                                configuration: ExposureConfiguration) -> Double {
        let scansScore = window.scans.reduce(Double(0)) { result, scan in
            result + (Double(scan.secondsSinceLastScan) * self.getAttenuationMultiplier(forAttenuation: scan.typicalAttenuation, configuration: configuration))
        }

        return (scansScore * getReportTypeMultiplier(reportType: window.diagnosisReportType, configuration: configuration) * getInfectiousnessMultiplier(infectiousness: window.infectiousness, configuration: configuration))
    }

    private func getAttenuationMultiplier(forAttenuation attenuationDb: UInt8,
                                          configuration: ExposureConfiguration) -> Double {

        var bucket = 3 // Default to "Other" bucket

        if attenuationDb <= configuration.attenuationBucketThresholdDb[0] {
            bucket = 0
        } else if attenuationDb <= configuration.attenuationBucketThresholdDb[1] {
            bucket = 1
        } else if attenuationDb <= configuration.attenuationBucketThresholdDb[2] {
            bucket = 2
        }

        return configuration.attenuationBucketWeights[bucket]
    }

    private func getReportTypeMultiplier(reportType: ENDiagnosisReportType,
                                         configuration: ExposureConfiguration) -> Double {
        return configuration.reportTypeWeights[safe: Int(reportType.rawValue)] ?? 0.0
    }

    private func getInfectiousnessMultiplier(infectiousness: ENInfectiousness,
                                             configuration: ExposureConfiguration) -> Double {
        return configuration.infectiousnessWeights[safe: Int(infectiousness.rawValue)] ?? 0.0
    }
}
