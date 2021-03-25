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
    /// Gets the most recent day (if any) on which the user was considered "at risk" according to the given ExposureWindows and ExposureConfiguration.
    /// - Parameters:
    ///   - windows: ExposureWindows as returned from the GAEN API.
    ///   - configuration: The configuration that includes the parameters that are used to determine the risk per window or per day.
    /// - Returns: The most recent day on which the user was considered to have had a risky exposure.
    func getLastExposureDate(fromWindows windows: [ExposureWindow], withConfiguration configuration: ExposureConfiguration) -> Date?
}

class RiskCalculationController: RiskCalculationControlling, Logging {

    /// Gets the most recent day (if any) on which the user was considered "at risk" according to the given ExposureWindows and ExposureConfiguration.
    /// - Parameters:
    ///   - windows: ExposureWindows as returned from the GAEN API.
    ///   - configuration: The configuration that includes the parameters that are used to determine the risk per window or per day.
    /// - Returns: The most recent day on which the user was considered to have had a risky exposure.
    func getLastExposureDate(fromWindows windows: [ExposureWindow], withConfiguration configuration: ExposureConfiguration) -> Date? {

        self.logDebug("Risk Calculation - Starting Exposure Risk Calculation")

        guard !windows.isEmpty else {
            self.logDebug("Risk Calculation - No Exposure Windows found")
            return nil
        }

        let dailyScores = getDailyRiskScores(windows: windows, configuration: configuration)

        self.logDebug("Risk Calculation - Exposure Windows: \(windows.count). Daily risk scores: \(dailyScores)")

        let lastDayOverMinimumRiskScore = dailyScores
            .filter { $0.value >= Double(configuration.minimumRiskScore) }
            .map { $0.key }
            .sorted()
            .last

        if let exposureDate = lastDayOverMinimumRiskScore {
            self.logDebug("Risk Calculation - Latest day over minimum risk score: \(exposureDate) (minimum score is \(configuration.minimumRiskScore))")
        } else {
            self.logDebug("Risk Calculation - No date found with riskscore over minimumRiskScore (\(configuration.minimumRiskScore)")
        }

        return lastDayOverMinimumRiskScore
    }

    /// Gets a list of daily risk scores, calculated from the given exposure windows.
    /// - Parameters:
    ///   - windows: Exposure windows to base the daily risk scores on
    ///   - configuration: Configuration that includes calculation parameters
    /// - Returns: A dictionary where keys are a date and the value is the risk score on that specific date
    private func getDailyRiskScores(windows: [ExposureWindow], configuration: ExposureConfiguration) -> [Date: Double] {

        var perDayScore = [Date: Double]()
        windows.forEach { window in

            let windowScore = self.getWindowScore(window: window, configuration: configuration)

            // Windows are only included in the calculation if their score reaches the minimum window score
            if windowScore >= configuration.minimumWindowScore {
                perDayScore[window.date] = (perDayScore[window.date] ?? 0.0) + windowScore
            }
        }

        return perDayScore
    }

    /// Calculates the risk score associated with a single exposure window based on the exposure seconds, attenuation, and report type.
    /// - Parameters:
    ///   - window: Exposure window to calculate the risk score of
    ///   - configuration: Configuration that includes calculation parameters
    /// - Returns: A risk score for the given exposure window
    private func getWindowScore(window: ExposureWindow, configuration: ExposureConfiguration) -> Double {

        let scansScore = window.scans.reduce(Double(0)) { result, scan in
            let secondsSinceLastScan = Double(scan.secondsSinceLastScan)
            let attenuationMultiplier = self.getAttenuationMultiplier(forAttenuation: scan.typicalAttenuation, configuration: configuration)
            let scanScore = result + (secondsSinceLastScan * attenuationMultiplier)
            self.logDebug("ExposureWindow Scan: typicalAttenuation: \(scan.typicalAttenuation), attenuationMultiplier: \(attenuationMultiplier), secondsSinceLastScan: \(scan.secondsSinceLastScan), scanScore: \(scanScore)")
            return scanScore
        }

        let reportTypeMultiplier = getReportTypeMultiplier(reportType: window.diagnosisReportType, configuration: configuration)
        self.logDebug("ReportTypeMultiplier for reportType \(window.diagnosisReportType): \(reportTypeMultiplier)")

        let infectiousnessMultiplier = getInfectiousnessMultiplier(infectiousness: window.infectiousness, configuration: configuration)
        self.logDebug("infectiousnessMultiplier for infectiousness \(window.infectiousness): \(infectiousnessMultiplier)")

        let windowScore = scansScore * reportTypeMultiplier * infectiousnessMultiplier
        self.logDebug("windowScore: \(windowScore) (minimum window score is: \(configuration.minimumWindowScore))")

        return windowScore
    }

    /// Gets a multiplier value for the given attentuation level. The window's duration of the exposure will be multiplied by this value
    /// - Parameters:
    ///   - attenuationDb: The (typical) attenuatuation of the exposure window
    ///   - configuration: Configuration that includes calculation parameters
    /// - Returns: A multipler for the windows exposure durection (secondsSinceLastScan)
    private func getAttenuationMultiplier(forAttenuation attenuationDb: UInt8, configuration: ExposureConfiguration) -> Double {

        let bucket: Int

        if attenuationDb <= configuration.attenuationBucketThresholdDb[0] {
            bucket = 0
        } else if attenuationDb <= configuration.attenuationBucketThresholdDb[1] {
            bucket = 1
        } else if attenuationDb <= configuration.attenuationBucketThresholdDb[2] {
            bucket = 2
        } else {
            bucket = 3
        }

        return configuration.attenuationBucketWeights[safe: bucket] ?? 0.0
    }

    /// Gets a multiplier value for the given report type. The combined score of the scans in an exposure window will be multiplied by this value
    /// - Parameters:
    ///   - reportType: The diagnosis report type of the exposure window
    ///   - configuration: Configuration that includes calculation parameters
    /// - Returns: A multiplier for the windows scan score
    private func getReportTypeMultiplier(reportType: ENDiagnosisReportType, configuration: ExposureConfiguration) -> Double {
        return configuration.reportTypeWeights[safe: Int(reportType.rawValue)] ?? 0.0
    }

    /// Gets a multiplier value for the given infectiousness level. The combined score of the scans in an exposure window will be multiplied by this value
    /// - Parameters:
    ///   - infectiousness: The infectiousness level of an exposure window
    ///   - configuration: Configuration that includes calculation parameters
    /// - Returns: A multiplier for the windows scan score
    private func getInfectiousnessMultiplier(infectiousness: ENInfectiousness, configuration: ExposureConfiguration) -> Double {
        return configuration.infectiousnessWeights[safe: Int(infectiousness.rawValue)] ?? 0.0
    }
}
