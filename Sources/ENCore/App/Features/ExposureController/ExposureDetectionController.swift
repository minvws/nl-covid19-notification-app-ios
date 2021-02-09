/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ExposureNotification
import Foundation
import RxSwift

struct V2ExposureDetectionResult {
    let wasExposed: Bool
}

enum ScoreType {
    case sum
    case max
}

class ExposureDetectionController {

    private let exposureManager: ExposureManaging

    init(exposureManager: ExposureManaging) {
        self.exposureManager = exposureManager
    }

    func detectExposures(configuration: ExposureConfiguration, diagnosisKeyURLs: [URL]) -> Single<V2ExposureDetectionResult> {

        return getExposureSummary(configuration: configuration, diagnosisKeyURLs: diagnosisKeyURLs)
            .flatMap(getExposureWindows)
            .flatMap(detectExposures)
    }

    private func getExposureSummary(configuration: ExposureConfiguration, diagnosisKeyURLs: [URL]) -> Single<ExposureDetectionSummary?> {

        return .create { (observer) -> Disposable in

            self.exposureManager.detectExposures(configuration: configuration,
                                                 diagnosisKeyURLs: diagnosisKeyURLs) { summaryResult in

                if case let .failure(error) = summaryResult {
                    observer(.failure(error))
                    return
                }

                guard case let .success(summary) = summaryResult else {
                    observer(.success(nil))
                    return
                }

                observer(.success(summary))
            }

            return Disposables.create()
        }
    }

    private func getExposureWindows(fromSummary summary: ExposureDetectionSummary?) -> Single<[ExposureWindow]?> {

        guard let summary = summary else {
            return .just([])
        }

        return .create { (observer) -> Disposable in

            self.exposureManager.getExposureWindows(summary: summary) { windowResult in
                if case let .failure(error) = windowResult {
                    observer(.failure(error))
                    return
                }

                guard case let .success(windows) = windowResult else {
                    observer(.success(nil))
                    return
                }

                observer(.success(windows))
            }

            return Disposables.create()
        }
    }

    private func detectExposures(inWindows exposureWindows: [ExposureWindow]?) -> Single<V2ExposureDetectionResult> {
        return .create { (observer) -> Disposable in

            let wasExposed = exposureWindows?.isEmpty == false

            exposureWindows?.forEach { window in
                window.scanInstances.forEach { scanInstance in
                }
            }
            observer(.success(V2ExposureDetectionResult(wasExposed: wasExposed)))

            return Disposables.create()
        }
    }

    // Gets the daily list of risk scores from the given exposure windows.
    private func getDailyRiskScores(windows: [ExposureWindow],
                                    scoreType: ScoreType = .max,
                                    withConfiguration configuration: V2ExposureConfiguration) -> [Double: Double] {
        var perDayScore = [Double: Double]()
        windows.forEach { window in

            let date: Double = window.date.timeIntervalSince1970
            let windowScore = self.getWindowScore(window: window, withConfiguration: configuration)

            if windowScore >= configuration.minimumWindowScore {
                switch scoreType {
                case ScoreType.max:
                    perDayScore[date] = max(perDayScore[date] ?? 0.0, windowScore)
                case ScoreType.sum:
                    perDayScore[date] = perDayScore[date] ?? 0.0 + windowScore
                }
            }
        }
        return perDayScore
    }

    // Computes the risk score associated with a single window based on the exposure seconds, attenuation, and report type.
    private func getWindowScore(window: ExposureWindow, withConfiguration configuration: V2ExposureConfiguration) -> Double {
        let scansScore = window.scanInstances.reduce(Double(0)) { result, scan in
            result + (Double(scan.secondsSinceLastScan) * self.getAttenuationMultiplier(forAttenuation: scan.typicalAttenuation, withConfiguration: configuration))
        }

        return (scansScore * getReportTypeMultiplier(reportType: window.diagnosisReportType, withConfiguration: configuration) * getInfectiousnessMultiplier(infectiousness: window.infectiousness, withConfiguration: configuration))
    }

    private func getAttenuationMultiplier(forAttenuation attenuationDb: UInt8, withConfiguration configuration: V2ExposureConfiguration) -> Double {

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

    private func getReportTypeMultiplier(reportType: ENDiagnosisReportType, withConfiguration configuration: V2ExposureConfiguration) -> Double {
        return configuration.reportTypeWeights[safe: Int(reportType.rawValue)] ?? 0.0
    }

    private func getInfectiousnessMultiplier(infectiousness: ENInfectiousness, withConfiguration configuration: V2ExposureConfiguration) -> Double {
        return configuration.infectiousnessWeights[safe: Int(infectiousness.rawValue)] ?? 0.0
    }
}
