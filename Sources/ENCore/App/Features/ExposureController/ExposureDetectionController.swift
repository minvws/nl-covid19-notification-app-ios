/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
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

class ExposureDetectionController: Logging {

    private let exposureManager: ExposureManaging
    private let storageController: StorageControlling
    private let localPathProvider: LocalPathProviding
    private let fileManager: FileManaging

    init(exposureManager: ExposureManaging,
         storageController: StorageControlling,
         localPathProvider: LocalPathProviding,
         fileManager: FileManaging) {

        self.exposureManager = exposureManager
        self.storageController = storageController
        self.localPathProvider = localPathProvider
        self.fileManager = fileManager
    }

    func detectExposures(configuration: ExposureConfiguration, diagnosisKeyURLs: [URL]) -> Single<ExposureDetectionResult> {

        guard let exposureKeySetsStorageUrl = localPathProvider.path(for: .exposureKeySets) else {
            self.logDebug("ExposureDataOperationProviderImpl: localPathProvider failed to find path for exposure keysets")
            return .error(ExposureDataError.internalError)
        }

        let unprocessedKeySetHolders = getUnprocessedKeySetHolders()

        if unprocessedKeySetHolders.count > 0 {
            logDebug("Processing \(unprocessedKeySetHolders.count) KeySets: \(unprocessedKeySetHolders.map { $0.identifier }.joined(separator: "\n"))")
        } else {
            logDebug("No additional keysets to process")
            return .just(ExposureDetectionResult(keySetDetectionResults: [], exposureSummary: nil, exposureReport: nil))
        }

        // v1
//        return getExposureSummary(configuration: configuration, diagnosisKeyURLs: diagnosisKeyURLs)
//            .flatMap(getExposureWindows)
//            .flatMap(detectExposuresFromExposureWindows)

        // v2
//        return getExposureSummary(configuration: configuration, diagnosisKeyURLs: diagnosisKeyURLs)
//            .flatMap(getExposureWindows)
//            .flatMap(detectExposuresFromExposureWindows)
    }

    // MARK: - Private

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

    struct DetectionInput {
        let diagnosisKeyUrls: [URL]
        let validKeySetHolderResults: [ExposureKeySetDetectionResult]
        let invalidKeySetHolderResults: [ExposureKeySetDetectionResult]
    }

    private func getUnprocessedKeySetHolders() -> [ExposureKeySetHolder] {
        let keySetHolders: [ExposureKeySetHolder] = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []
        return keySetHolders.filter { $0.processed == false }
    }

//    private func createDetectionInput(keySetHolders: [ExposureKeySetHolder], exposureKeySetsStorageUrl: URL) -> Single<DetectionInput> {
//
//        // filter out keysets with missing local files
//        let validKeySetHolders = keySetHolders.filter {
//            self.verifyLocalFileUrl(forKeySetsHolder: $0, exposureKeySetsStorageUrl: exposureKeySetsStorageUrl)
//        }
//
//        let invalidKeySetHolders = keySetHolders.filter { keySetHolder in
//            !validKeySetHolders.contains { $0.identifier == keySetHolder.identifier }
//        }
//
//        logDebug("Invalid KeySetHolders: \(invalidKeySetHolders.map { $0.identifier })")
//        logDebug("Valid KeySetHolders: \(validKeySetHolders.map { $0.identifier })")
//
//        // create results for the keySetHolders with missing local files
//        let invalidKeySetHolderResults = invalidKeySetHolders.map { keySetHolder in
//            return ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
//                                                 processDate: nil,
//                                                 isValid: false)
//        }
//
//        // Determine if we are limited by the number of daily API calls or KeySets
    ////        let applicationIsInBackground = application.isInBackground
    ////        let numberOfDailyAPICallsLeft = getNumberOfDailyAPICallsLeft(inBackground: applicationIsInBackground)
    ////        let numberOfDailyKeySetsLeft = getNumberOfDailyKeySetsLeft()
//
//        // get most recent keySetHolders and limit by `numberOfDailyKeysetsLeft`
    ////        let keySetHoldersToProcess = selectKeySetHoldersToProcess(from: validKeySetHolders, maximum: numberOfDailyKeySetsLeft)
//
//        // temporary code
//        let numberOfDailyAPICallsLeft = 10
//        let keySetHoldersToProcess = validKeySetHolders
//
//        guard !keySetHoldersToProcess.isEmpty, numberOfDailyAPICallsLeft > 0 else {
//            logDebug("Nothing left to process")
//
//            // nothing (left) to process, return an empty summary
//            let validKeySetHolderResults = validKeySetHolders.map { keySetHolder in
//                return ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
//                                                     processDate: nil,
//                                                     isValid: true)
//            }
//
//            let detectionInput = DetectionInput(diagnosisKeyUrls: [],
//                                                validKeySetHolderResults: validKeySetHolderResults,
//                                                invalidKeySetHolderResults: invalidKeySetHolderResults)
//
//            return .just(detectionInput)
//        }
//
//        let diagnosisKeyUrls = keySetHoldersToProcess.flatMap { (keySetHolder) -> [URL] in
//            if let sigFile = signatureFileUrl(forKeySetHolder: keySetHolder, exposureKeySetsStorageUrl: exposureKeySetsStorageUrl), let binFile = binaryFileUrl(forKeySetHolder: keySetHolder, exposureKeySetsStorageUrl: exposureKeySetsStorageUrl) {
//                return [sigFile, binFile]
//            }
//            return []
//        }
//
//        let detectionInput = DetectionInput(diagnosisKeyUrls: diagnosisKeyUrls,
//                                            validKeySetHolderResults: [],
//                                            invalidKeySetHolderResults: invalidKeySetHolderResults)
//
//    }

    private func detectExposuresFromSummary(_ exposureDetectionSummary: ExposureDetectionSummary?,
                                            keySetDetectionResults: [ExposureKeySetDetectionResult],
                                            withConfiguration configuration: V2ExposureConfiguration) -> Single<ExposureDetectionResult> {

        let uncompletedExposureDetectionResult = ExposureDetectionResult(keySetDetectionResults: keySetDetectionResults,
                                                                         exposureSummary: exposureDetectionSummary,
                                                                         exposureReport: nil)

        guard let summary = exposureDetectionSummary else {
            return .just(uncompletedExposureDetectionResult)
        }

        guard summary.maximumRiskScore >= UInt(configuration.minimumWindowScore) else {
            self.logDebug("Risk Score not high enough to see this as an exposure")
            return .just(uncompletedExposureDetectionResult)
        }

        if let daysSinceLastExposure = self.daysSinceLastExposure() {
            self.logDebug("Had previous exposure \(daysSinceLastExposure) days ago")

            if summary.daysSinceLastExposure >= daysSinceLastExposure {
                self.logDebug("Previous exposure was newer than new found exposure - skipping notification")
                return .just(uncompletedExposureDetectionResult)
            }
        }

        guard let date = Calendar.current.date(byAdding: .day, value: -summary.daysSinceLastExposure, to: Date()) else {
            self.logError("Error triggering notification for \(summary), could not create date")
            return .just(uncompletedExposureDetectionResult)
        }

        let completedDetectionResult = ExposureDetectionResult(keySetDetectionResults: keySetDetectionResults,
                                                               exposureSummary: exposureDetectionSummary,
                                                               exposureReport: ExposureReport(date: date))

        return .just(completedDetectionResult)
    }

    private func detectExposuresFromExposureWindows(_ exposureWindows: [ExposureWindow]?) -> Single<V2ExposureDetectionResult> {

        let wasExposed = exposureWindows?.isEmpty == false

        exposureWindows?.forEach { window in
            window.scanInstances.forEach { scanInstance in
            }
        }

        return .just(V2ExposureDetectionResult(wasExposed: wasExposed))
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

    private func daysSinceLastExposure() -> Int? {
        let today = Date()

        guard
            let lastExposureDate = lastStoredExposureReport()?.date,
            let dayCount = Calendar.current.dateComponents([.day], from: lastExposureDate, to: today).day
        else {
            return nil
        }

        return dayCount
    }

    private func lastStoredExposureReport() -> ExposureReport? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureReport)
    }

    /// Verifies whether the KeySetHolder URLs point to valid files
    private func verifyLocalFileUrl(forKeySetsHolder keySetHolder: ExposureKeySetHolder, exposureKeySetsStorageUrl: URL) -> Bool {
        var isDirectory = ObjCBool(booleanLiteral: false)

        // verify whether sig and bin files are present
        guard let sigPath = signatureFileUrl(forKeySetHolder: keySetHolder, exposureKeySetsStorageUrl: exposureKeySetsStorageUrl)?.path,
            fileManager.fileExists(atPath: sigPath,
                                   isDirectory: &isDirectory), isDirectory.boolValue == false else {
            return false
        }

        guard let binPath = binaryFileUrl(forKeySetHolder: keySetHolder, exposureKeySetsStorageUrl: exposureKeySetsStorageUrl)?.path,
            fileManager.fileExists(atPath: binPath,
                                   isDirectory: &isDirectory), isDirectory.boolValue == false else {
            return false
        }

        return true
    }

    private func signatureFileUrl(forKeySetHolder keySetHolder: ExposureKeySetHolder, exposureKeySetsStorageUrl: URL) -> URL? {
        guard let signatureFilename = keySetHolder.signatureFilename else {
            return nil
        }

        return exposureKeySetsStorageUrl.appendingPathComponent(signatureFilename)
    }

    private func binaryFileUrl(forKeySetHolder keySetHolder: ExposureKeySetHolder, exposureKeySetsStorageUrl: URL) -> URL? {
        guard let binaryFilename = keySetHolder.binaryFilename else {
            return nil
        }

        return exposureKeySetsStorageUrl.appendingPathComponent(binaryFilename)
    }
}
