/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import UIKit

private struct DetectionInput {
    let exposureKeySetsStorageUrl: URL
    let applicationInBackground: Bool
    let storedKeysetHolders: [ExposureKeySetHolder]

    var unprocessedExposureKeySetHolders: [ExposureKeySetHolder] {
        storedKeysetHolders.filter { $0.processed == false }
    }

    var numberOfProcessedKeySetsInLast24Hours: Int {
        guard let cutOffDate = Calendar.current.date(byAdding: .hour, value: -24, to: currentDate()) else {
            return 0
        }

        let wasProcessedInLast24h: (ExposureKeySetHolder) -> Bool = { keySetHolder in
            guard let processDate = keySetHolder.processDate else {
                return false
            }

            return processDate > cutOffDate
        }

        return storedKeysetHolders
            .filter(wasProcessedInLast24h)
            .count
    }
}

private struct DetectionOutput {
    let daysSinceLastExposure: Int?
    let detectionHappenedInBackground: Bool
    let keySetDetectionResults: [ExposureKeySetDetectionResult]
    let exposureSummary: ExposureDetectionSummary?
    let exposureReport: ExposureReport?
}

private struct ExposureKeySetDetectionResult {
    let keySetHolder: ExposureKeySetHolder
    let processDate: Date?
    let isValid: Bool
}

struct ExposureReport: Codable {
    let date: Date
}

#if USE_DEVELOPER_MENU || DEBUG

    struct ProcessExposureKeySetsDataOperationOverrides {
        static var respectMaximumDailyKeySets = true
    }

#endif

/// @mockable
protocol ProcessExposureKeySetsDataOperationProtocol {
    func execute() -> Completable
}

final class ProcessExposureKeySetsDataOperation: ProcessExposureKeySetsDataOperationProtocol, Logging {
    // the detectExposures API is limited to 15 keysets or calls a day
    // https://developer.apple.com/documentation/exposurenotification/enmanager/3586331-detectexposures
    private let maximumDailyOfKeySetsToProcess = 15 // iOS 13.5

    // iOS 13.6+ is limited to 15 GAEN API calls in total per 24 hours
    // Because we want to make sure the scheduled background processes
    // can always execute, we explicitly reserve 6 of those calls for the background.
    private let maximumDailyForegroundExposureDetectionAPICalls = 9
    private let maximumDailyBackgroundExposureDetectionAPICalls = 6

    /// If an exposure happened more than x days ago, ignore it
    private let daysSinceExposureCutOff = 14

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         exposureManager: ExposureManaging,
         localPathProvider: LocalPathProviding,
         exposureDataController: ExposureDataControlling,
         configuration: ExposureConfiguration,
         userNotificationController: UserNotificationControlling,
         application: ApplicationControlling,
         fileManager: FileManaging,
         environmentController: EnvironmentControlling,
         riskCalculationController: RiskCalculationControlling) {
        self.networkController = networkController
        self.storageController = storageController
        self.exposureManager = exposureManager
        self.localPathProvider = localPathProvider
        self.exposureDataController = exposureDataController
        self.userNotificationController = userNotificationController
        self.application = application
        self.fileManager = fileManager
        self.environmentController = environmentController
        self.riskCalculationController = riskCalculationController
        self.configuration = configuration
    }

    func execute() -> Completable {
        self.logDebug("--- START PROCESSING KEYSETS ---")

        guard let exposureKeySetsStorageUrl = localPathProvider.path(for: .exposureKeySets) else {
            self.logDebug("ExposureDataOperationProviderImpl: localPathProvider failed to find path for exposure keysets")
            return .error(ExposureDataError.internalError)
        }

        return getDetectionInput(exposureKeySetsStorageUrl: exposureKeySetsStorageUrl)
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .flatMap(detectExposures) // Batch detect exposures
            .flatMap(persistResult) // Persist created keySetHolders in local storage to remember which ones have been processed correctly
            .flatMap(createExposureReport) // Create an exposureReport and trigger a local notification
            .flatMap(ignoreFirstV2Exposure) // Ignore the first exposure on the v2 framework to prevent re-triggering of historical exposures
            .flatMap(notifyUserOfExposure) // Send a local notification to inform the user of an exposure if neccesary
            .flatMap(persistExposureReport) // Store the ExposureReport (including exposure date)
            .flatMap(storeAsPreviousExposureDate) // Store exposure date in previous exposure dates array
            // remove all blobs for all keySetHolders - successful ones are processed and
            // should not be processed again. Failed ones should be downloaded again and
            // have already been removed from the list of keySetHolders in localStorage by persistResult(_:)
            .flatMapCompletable {
                self.removeBlobs(forDetectionOutput: $0, exposureKeySetsStorageUrl: exposureKeySetsStorageUrl)
            }
            .do(onCompleted: {
                self.logDebug("--- END PROCESSING KEYSETS ---")
            })
    }

    // MARK: - Private

    private func getDetectionInput(exposureKeySetsStorageUrl: URL) -> Single<DetectionInput> {
        let input = Single<DetectionInput>.create { observer in

            DispatchQueue.global(qos: .userInitiated).async {
                let storedKeysetHolders = self.storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []

                // Main thread is required for accessing `application.isInBackground`
                DispatchQueue.main.async {
                    let input = DetectionInput(
                        exposureKeySetsStorageUrl: exposureKeySetsStorageUrl,
                        applicationInBackground: self.application.isInBackground(),
                        storedKeysetHolders: storedKeysetHolders
                    )

                    observer(.success(input))
                }
            }

            return Disposables.create()
        }

        return input
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

    /// Returns ExposureKeySetDetectionResult in case of a success, or in case of an error that's
    /// not related to the framework's inactiveness. When an error is thrown from here exposure detection
    /// should be stopped until the user enables the framework
    private func detectExposures(_ detectionInput: DetectionInput) -> Single<DetectionOutput> {

        // filter out keysets with missing local files
        let validKeySetHolders = detectionInput.unprocessedExposureKeySetHolders.filter {
            self.verifyLocalFileUrl(forKeySetsHolder: $0, exposureKeySetsStorageUrl: detectionInput.exposureKeySetsStorageUrl)
        }
        let invalidKeySetHolders = detectionInput.unprocessedExposureKeySetHolders.filter { keySetHolder in
            !validKeySetHolders.contains { $0.identifier == keySetHolder.identifier }
        }

        logDebug("Invalid KeySetHolders: \(invalidKeySetHolders.count)")
        logDebug("Valid KeySetHolders: \(validKeySetHolders.count)")

        // create results for the keySetHolders with missing local files
        let invalidKeySetHolderResults = invalidKeySetHolders.map { keySetHolder in
            return ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
                                                 processDate: nil,
                                                 isValid: false)
        }

        // Determine if we are limited by the number of daily API calls or KeySets
        let numberOfDailyAPICallsLeft = getNumberOfDailyAPICallsLeft(inBackground: detectionInput.applicationInBackground)
        let numberOfDailyKeySetsLeft = getNumberOfDailyKeySetsLeft(detectionInput: detectionInput)

        // get most recent keySetHolders and limit by `numberOfDailyKeysetsLeft`
        let keySetHoldersToProcess = selectKeySetHoldersToProcess(from: validKeySetHolders, maximum: numberOfDailyKeySetsLeft)

        guard !keySetHoldersToProcess.isEmpty, numberOfDailyAPICallsLeft > 0 else {
            logDebug("Nothing left to process")

            // nothing (left) to process, return an empty summary
            let validKeySetHolderResults = validKeySetHolders.map { keySetHolder in
                return ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
                                                     processDate: nil,
                                                     isValid: true)
            }

            if keySetHoldersToProcess.isEmpty {
                self.updateLastProcessingDate()
            }

            return .just(DetectionOutput(daysSinceLastExposure: nil,
                                         detectionHappenedInBackground: detectionInput.applicationInBackground,
                                         keySetDetectionResults: validKeySetHolderResults + invalidKeySetHolderResults,
                                         exposureSummary: nil,
                                         exposureReport: nil))
        }

        let exposureKeySetsStorageUrl = detectionInput.exposureKeySetsStorageUrl
        let diagnosisKeyUrls = keySetHoldersToProcess.flatMap { (keySetHolder) -> [URL] in
            if let sigFile = signatureFileUrl(forKeySetHolder: keySetHolder, exposureKeySetsStorageUrl: exposureKeySetsStorageUrl), let binFile = binaryFileUrl(forKeySetHolder: keySetHolder, exposureKeySetsStorageUrl: exposureKeySetsStorageUrl) {
                return [sigFile, binFile]
            }
            return []
        }

        logDebug("Detect exposures for \(keySetHoldersToProcess.count) keySets: \(keySetHoldersToProcess.map { $0.identifier })")

        return updateNumberOfApiCallsMade(inBackground: detectionInput.applicationInBackground)
            .andThen(detectExposures(applicationIsInBackground: detectionInput.applicationInBackground, diagnosisKeyUrls: diagnosisKeyUrls, invalidKeySetHolderResults: invalidKeySetHolderResults, keySetHoldersToProcess: keySetHoldersToProcess))
    }

    private func detectExposures(applicationIsInBackground: Bool,
                                 diagnosisKeyUrls: [URL],
                                 invalidKeySetHolderResults: [ExposureKeySetDetectionResult],
                                 keySetHoldersToProcess: [ExposureKeySetHolder]) -> Single<DetectionOutput> {

        return .create { observer in

            self.logDebug("Detecting exposures for \(diagnosisKeyUrls.count) diagnosisKeyUrls")

            self.exposureManager.detectExposures(configuration: self.configuration,
                                                 diagnosisKeyURLs: diagnosisKeyUrls) { result in
                switch result {
                case let .success(summary):
                    self.logDebug("Successfully called detectExposures function of framework: \(String(describing: summary))")

                    let validKeySetHolderResults = keySetHoldersToProcess.map { keySetHolder in
                        return ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
                                                             processDate: currentDate(),
                                                             isValid: true)
                    }

                    let keySetHolderResults = invalidKeySetHolderResults + validKeySetHolderResults
                    let result = DetectionOutput(daysSinceLastExposure: nil,
                                                 detectionHappenedInBackground: applicationIsInBackground,
                                                 keySetDetectionResults: keySetHolderResults,
                                                 exposureSummary: summary,
                                                 exposureReport: nil)

                    self.updateLastProcessingDate()

                    observer(.success(result))

                case let .failure(error):
                    self.logDebug("Failure when detecting exposures: \(error)")

                    switch error {
                    case .bluetoothOff, .disabled, .notAuthorized, .restricted:
                        observer(.failure(error.asExposureDataError))
                    case .internalTypeMismatch:
                        observer(.failure(ExposureDataError.internalError))
                    case .rateLimited:
                        observer(.failure(ExposureDataError.internalError))
                    case .signatureValidationFailed:

                        // if we were already using the old fallback API, set the flag to 'false' to indicate we want to use the fallback. This will force the app to use the normal / new API in the next EKS run.
                        // if we were NOT on the fallback API yet, set the flag to 'true' to indicate that the next EKS run needs to use the fallback API
                        let currentlyusingFallbackEKSEndpoint = self.storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.useFallbackEKSEndpoint) ?? false
                        self.storageController.store(object: !currentlyusingFallbackEKSEndpoint, identifiedBy: ExposureDataStorageKey.useFallbackEKSEndpoint, completion: { _ in })

                        // mark all keysets as invalid so they will be redownloaded again
                        let result = self.getInvalidDetectionOutput(applicationIsInBackground: applicationIsInBackground, invalidKeySetHolderResults: invalidKeySetHolderResults, keySetHoldersToProcess: keySetHoldersToProcess)

                        // We still return successful here because validation errors should not be shown to the users but handled silently by the app
                        self.updateLastProcessingDate()

                        observer(.success(result))

                    default:
                        // something else is going wrong with exposure detection
                        // mark all keysets as invalid so they will be redownloaded again
                        let result = self.getInvalidDetectionOutput(applicationIsInBackground: applicationIsInBackground, invalidKeySetHolderResults: invalidKeySetHolderResults, keySetHoldersToProcess: keySetHoldersToProcess)
                        observer(.success(result))
                    }
                }
            }

            return Disposables.create()
        }
    }

    private func getInvalidDetectionOutput(
        applicationIsInBackground: Bool,
        invalidKeySetHolderResults: [ExposureKeySetDetectionResult],
        keySetHoldersToProcess: [ExposureKeySetHolder]
    ) -> DetectionOutput {

        let validKeySetHolderResults = keySetHoldersToProcess.map { keySetHolder in
            return ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
                                                 processDate: nil,
                                                 isValid: false)
        }

        let keySetHolderResults = invalidKeySetHolderResults + validKeySetHolderResults

        return DetectionOutput(daysSinceLastExposure: nil,
                               detectionHappenedInBackground: applicationIsInBackground,
                               keySetDetectionResults: keySetHolderResults,
                               exposureSummary: nil,
                               exposureReport: nil)
    }

    /// Updates the local keySetHolder storage with the latest results
    private func persistResult(_ detectionOutput: DetectionOutput) -> Single<DetectionOutput> {
        return .create { (observer) -> Disposable in

            let selectKeySetDetectionResult: (ExposureKeySetHolder) -> ExposureKeySetDetectionResult? = { keySetHolder in
                // find result that belongs to the keySetHolder
                detectionOutput.keySetDetectionResults.first { result in result.keySetHolder.identifier == keySetHolder.identifier }
            }

            self.storageController.requestExclusiveAccess { storageController in
                let storedKeySetHolders = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []
                var keySetHolders: [ExposureKeySetHolder] = []

                storedKeySetHolders.forEach { keySetHolder in
                    guard let result = selectKeySetDetectionResult(keySetHolder) else {
                        // no result for this one, just append and process it next time
                        keySetHolders.append(keySetHolder)
                        return
                    }

                    if result.processDate != nil || result.isValid {
                        // only store correctly processed or valid results - forget about incorrectly processed ones
                        // and try to download those again next time
                        keySetHolders.append(ExposureKeySetHolder(identifier: keySetHolder.identifier,
                                                                  signatureFilename: keySetHolder.signatureFilename,
                                                                  binaryFilename: keySetHolder.binaryFilename,
                                                                  processDate: result.processDate,
                                                                  creationDate: keySetHolder.creationDate))
                    }
                }

                storageController.store(object: keySetHolders,
                                        identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) { error in

                    if error != nil {
                        observer(.failure(ExposureDataError.internalError))
                    } else {
                        observer(.success(detectionOutput))
                    }
                }
            }

            return Disposables.create()
        }
    }

    /// Removes binary files for processed or invalid keySetHolders
    private func removeBlobs(forDetectionOutput detectionOutput: DetectionOutput, exposureKeySetsStorageUrl: URL) -> Completable {

        return .create { (observer) -> Disposable in

            let keySetHolders = detectionOutput
                .keySetDetectionResults
                .filter { $0.processDate != nil || $0.isValid == false }
                .map { $0.keySetHolder }

            keySetHolders.forEach { keySetHolder in
                if let sigFileURL = self.signatureFileUrl(forKeySetHolder: keySetHolder, exposureKeySetsStorageUrl: exposureKeySetsStorageUrl) {
                    try? self.fileManager.removeItem(at: sigFileURL)
                }

                if let binFileURL = self.binaryFileUrl(forKeySetHolder: keySetHolder, exposureKeySetsStorageUrl: exposureKeySetsStorageUrl) {
                    try? self.fileManager.removeItem(at: binFileURL)
                }
            }
            observer(.completed)

            return Disposables.create()
        }
    }

    private func updateNumberOfApiCallsMade(inBackground: Bool) -> Completable {
        return .create { (observer) -> Disposable in
            self.storageController.requestExclusiveAccess { storageController in
                let storageKey: CodableStorageKey<[Date]> = inBackground ? ExposureDataStorageKey.exposureApiBackgroundCallDates : ExposureDataStorageKey.exposureApiCallDates
                var calls = storageController.retrieveObject(identifiedBy: storageKey) ?? []

                calls = [currentDate()] + calls
                self.logDebug("Most recent API calls \(calls)")

                let maximumNumberOfAPICalls = inBackground ? self.maximumDailyBackgroundExposureDetectionAPICalls : self.maximumDailyForegroundExposureDetectionAPICalls

                if calls.count > maximumNumberOfAPICalls {
                    calls = Array(calls.prefix(maximumNumberOfAPICalls))
                }

                storageController.store(object: calls, identifiedBy: storageKey) { error in
                    if error != nil {
                        observer(.error(ExposureDataError.internalError))
                    } else {
                        observer(.completed)
                    }
                }
            }

            return Disposables.create()
        }
    }

    private func getNumberOfExposureDetectionApiCallsInLast24Hours(inBackground: Bool = false) -> Int {
        let storageKey: CodableStorageKey<[Date]> = inBackground ? ExposureDataStorageKey.exposureApiBackgroundCallDates : ExposureDataStorageKey.exposureApiCallDates
        let apiCalls = storageController.retrieveObject(identifiedBy: storageKey) ?? []

        guard let cutOffDate = Calendar.current.date(byAdding: .hour, value: -24, to: currentDate()) else {
            return 0
        }

        let wasProcessedInLast24h: (Date) -> Bool = { date in
            return date > cutOffDate
        }

        return apiCalls
            .filter(wasProcessedInLast24h)
            .count
    }

    private func getNumberOfDailyAPICallsLeft(inBackground: Bool) -> Int {
        var numberOfCallsLeft = Int.max

        defer {
            logDebug("Number of API Calls (\(inBackground ? "in background" : "in foreground")) left today: \(numberOfCallsLeft)")
        }

        guard environmentController.gaenRateLimitingType == .dailyLimit else {
            return numberOfCallsLeft
        }

        let totalMaximumCalls = maximumDailyBackgroundExposureDetectionAPICalls + maximumDailyForegroundExposureDetectionAPICalls
        let maximumNumberOfAPICalls = inBackground ? maximumDailyBackgroundExposureDetectionAPICalls : maximumDailyForegroundExposureDetectionAPICalls
        let backgroundCallsDone = getNumberOfExposureDetectionApiCallsInLast24Hours(inBackground: true)
        let foregroundCallsDone = getNumberOfExposureDetectionApiCallsInLast24Hours(inBackground: false)
        let callsDoneInCurrentState = inBackground ? backgroundCallsDone : foregroundCallsDone
        numberOfCallsLeft = maximumNumberOfAPICalls - callsDoneInCurrentState

        // For legacy reasons, we also check if the combined total of calls doesn't exceed the combined daily maximum
        if (backgroundCallsDone + foregroundCallsDone) >= totalMaximumCalls {
            numberOfCallsLeft = 0
        }

        return numberOfCallsLeft
    }

    private func getNumberOfDailyKeySetsLeft(detectionInput: DetectionInput) -> Int {
        guard environmentController.gaenRateLimitingType == .fileLimit else {
            // iOS 13.6+ is not limited in the number of daily keysets but in the number of API calls
            logDebug("Number of keysets left to process today: infinite (no limit on iOS 13.6+)")
            return Int.max
        }

        #if USE_DEVELOPER_MENU || DEBUG
            if !ProcessExposureKeySetsDataOperationOverrides.respectMaximumDailyKeySets {
                logDebug("Number of keysets left to process today: infinite (ignoring limit via Developer Menu)")
                return Int.max
            }
        #endif

        let numberOfKeySetsLeftToProcess = maximumDailyOfKeySetsToProcess - detectionInput.numberOfProcessedKeySetsInLast24Hours
        logDebug("Number of keysets left to process today: \(numberOfKeySetsLeftToProcess)")

        return numberOfKeySetsLeftToProcess
    }

    private func selectKeySetHoldersToProcess(from keySetsHolders: [ExposureKeySetHolder], maximum: Int) -> [ExposureKeySetHolder] {

        let keySetHoldersToProcess = keySetsHolders
            .sorted(by: { first, second in first.creationDate < second.creationDate })

        guard keySetHoldersToProcess.isEmpty == false, maximum > 0 else {
            return []
        }

        return Array(keySetHoldersToProcess.prefix(maximum))
    }

    /// Creates the final ExposureReport that includes a date for which a risky exposure was detected
    private func createExposureReport(forDetectionOutput detectionOutput: DetectionOutput) -> Single<DetectionOutput> {

        guard environmentController.maximumSupportedExposureNotificationVersion == .version2 else {
            self.logError("GAEN API V2 not supported on device / platform")
            return .error(ExposureDataError.internalError)
        }

        let noExposureResult = DetectionOutput(daysSinceLastExposure: nil,
                                               detectionHappenedInBackground: detectionOutput.detectionHappenedInBackground,
                                               keySetDetectionResults: detectionOutput.keySetDetectionResults,
                                               exposureSummary: detectionOutput.exposureSummary,
                                               exposureReport: nil)

        guard let summary = detectionOutput.exposureSummary else {
            logDebug("No summary to trigger notification for")
            return .just(noExposureResult)
        }

        return .create { (observer) -> Disposable in

            self.exposureManager.getExposureWindows(summary: summary) { windowResult in
                if case let .failure(error) = windowResult {
                    self.logError("Risk Calculation - Error getting Exposure Windows: \(error)")
                    observer(.failure(error))
                    return
                }

                guard case let .success(exposureWindows) = windowResult, let windows = exposureWindows else {
                    self.logDebug("Risk Calculation - No Exposure Windows found")
                    observer(.success(noExposureResult))
                    return
                }

                let lastDayOverMinimumRiskScore = self.riskCalculationController.getLastExposureDate(fromWindows: windows, withConfiguration: self.configuration)

                guard let exposureDate = lastDayOverMinimumRiskScore else {
                    observer(.success(noExposureResult))
                    return
                }

                guard let daysSinceLastExposure = currentDate().days(sinceDate: exposureDate) else {
                    observer(.failure(ExposureDataError.internalError))
                    return
                }

                let output = DetectionOutput(daysSinceLastExposure: daysSinceLastExposure,
                                             detectionHappenedInBackground: detectionOutput.detectionHappenedInBackground,
                                             keySetDetectionResults: detectionOutput.keySetDetectionResults,
                                             exposureSummary: detectionOutput.exposureSummary,
                                             exposureReport: ExposureReport(date: exposureDate))

                observer(.success(output))
            }

            return Disposables.create()
        }
    }

    // When upgrading to the 2.0 version of the app from an app version that uses GAEN v1, We ignore any exposure we detect
    // on the first call to the GAEN API. We do this because it is likely that any such exposure would already have been seen by the user and it is actually a
    // re-trigger of the same exposure date caused by GAEN v2's "exposure memory".
    private func ignoreFirstV2Exposure(_ detectionOutput: DetectionOutput) -> Single<DetectionOutput> {

        let ignoreSingle: Single<DetectionOutput> = .create { (observer) -> Disposable in

            guard self.exposureDataController.ignoreFirstV2Exposure else {
                observer(.success(detectionOutput))
                return Disposables.create()
            }

            guard let exposureDate = detectionOutput.exposureReport?.date else {
                self.exposureDataController.ignoreFirstV2Exposure = false
                observer(.success(detectionOutput))
                return Disposables.create()
            }

            self.logDebug("Ignoring exposure detection run on v2 framework to prevent exposure that was potentially already seen on v1")

            self.logDebug("Storing previous exposure date: \(exposureDate)")

            self.exposureDataController
                .addPreviousExposureDate(exposureDate)
                .subscribe { event in

                    self.exposureDataController.ignoreFirstV2Exposure = false

                    switch event {
                    case let .error(error):
                        observer(.failure(error))
                    case .completed:
                        // Remove exposurereport from result in order to ignore it

                        let clearedDetectionOutput = DetectionOutput(daysSinceLastExposure: nil,
                                                                     detectionHappenedInBackground: detectionOutput.detectionHappenedInBackground,
                                                                     keySetDetectionResults: detectionOutput.keySetDetectionResults,
                                                                     exposureSummary: detectionOutput.exposureSummary,
                                                                     exposureReport: nil)

                        observer(.success(clearedDetectionOutput))
                    }

                }.disposed(by: self.disposeBag)

            return Disposables.create()
        }

        return ignoreSingle.subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }

    /// Determines wether or not the user needs to receive a notification for an exposure and triggers the notification if needed
    private func notifyUserOfExposure(_ detectionOutput: DetectionOutput) -> Single<DetectionOutput> {

        let emptyOutput = DetectionOutput(daysSinceLastExposure: nil,
                                          detectionHappenedInBackground: detectionOutput.detectionHappenedInBackground,
                                          keySetDetectionResults: detectionOutput.keySetDetectionResults,
                                          exposureSummary: detectionOutput.exposureSummary,
                                          exposureReport: nil)

        // Check if we actually found an exposure
        guard let exposureReport = detectionOutput.exposureReport, let daysSinceLastExposure = detectionOutput.daysSinceLastExposure else {
            return .just(emptyOutput)
        }

        // We only show a notification for exposures that happened within the last x days
        guard daysSinceLastExposure <= self.daysSinceExposureCutOff else {
            self.logDebug("Exposure was too long ago (\(daysSinceLastExposure) days). Ignore it")
            return .just(emptyOutput)
        }

        // We only show a notification if the found exposure was newer than the previously known exposure
        if let previousDaysSinceLastExposure = getStoredDaysSinceLastExposure(), previousDaysSinceLastExposure <= daysSinceLastExposure {
            if let lastExposureDate = lastStoredExposureReport()?.date {
                logDebug("lastExposureDate: \(lastExposureDate). exposureReport.date: \(exposureReport.date)")
            }
            logDebug("Previous exposure (\(previousDaysSinceLastExposure) days ago) was more recent than found exposure (\(daysSinceLastExposure) days ago) - skipping notification")
            return .just(emptyOutput)
        }

        // We only show a notification if the found exposure date was not found before
        if exposureDataController.isKnownPreviousExposureDate(exposureReport.date) {
            logDebug("Exposure on date \(exposureReport.date) was already detected before - skipping notification")
            return .just(emptyOutput)
        }

        logDebug("Triggering notification for \(exposureReport)")

        return .create { (observer) -> Disposable in

            self.userNotificationController.displayExposureNotification(daysSinceLastExposure: daysSinceLastExposure) { success in

                guard success else {
                    observer(.failure(ExposureDataError.internalError))
                    return
                }

                self.updateExposureFirstNotificationReceivedDate()

                /// Store the unseen notification date, but only when the app is in the background
                if !detectionOutput.detectionHappenedInBackground {
                    observer(.success(detectionOutput))
                    return
                }

                self.storageController.requestExclusiveAccess { storageController in
                    storageController.store(object: currentDate(),
                                            identifiedBy: ExposureDataStorageKey.lastUnseenExposureNotificationDate) { error in
                        if error != nil {
                            observer(.failure(ExposureDataError.internalError))
                        } else {
                            observer(.success(detectionOutput))
                        }
                    }
                }
            }

            return Disposables.create()
        }
    }

    private func storeAsPreviousExposureDate(_ detectionOutput: DetectionOutput) -> Single<DetectionOutput> {
        return .create { (observer) -> Disposable in

            guard let exposureDate = detectionOutput.exposureReport?.date else {
                observer(.success(detectionOutput))
                return Disposables.create()
            }

            self.exposureDataController
                .addPreviousExposureDate(exposureDate)
                .subscribe { event in
                    switch event {
                    case let .error(error):
                        observer(.failure(error))
                    case .completed:
                        observer(.success(detectionOutput))
                    }
                }.disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    /// Stores the exposureReport in local storage (which triggers the 'notified' state)
    private func persistExposureReport(_ detectionOutput: DetectionOutput) -> Single<DetectionOutput> {
        return .create { (observer) -> Disposable in
            guard let exposureReport = detectionOutput.exposureReport else {
                observer(.success(detectionOutput))
                return Disposables.create()
            }

            self.storageController.requestExclusiveAccess { storageController in
                let lastExposureReport = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureReport)

                if let lastExposureReport = lastExposureReport, lastExposureReport.date > exposureReport.date {
                    // already stored a newer report, ignore this one
                    observer(.success(detectionOutput))
                } else {
                    // store the new report
                    storageController.store(object: exposureReport,
                                            identifiedBy: ExposureDataStorageKey.lastExposureReport) { error in
                        if error != nil {
                            observer(.failure(ExposureDataError.internalError))
                        } else {
                            observer(.success(detectionOutput))
                        }
                    }
                }
            }

            return Disposables.create()
        }
    }

    /// Updates the date when this operation has last run
    private func updateLastProcessingDate() {

        let date = currentDate()

        self.logDebug("Updating last process date to \(date)")

        self.exposureDataController.updateLastSuccessfulExposureProcessingDate(date)
    }

    private func updateExposureFirstNotificationReceivedDate() {
        let date = currentDate()

        self.logDebug("Updating ExposureNotificationReceivedDate to \(date)")

        self.exposureDataController.updateExposureFirstNotificationReceivedDate(date)
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

    private func lastStoredExposureReport() -> ExposureReport? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureReport)
    }

    private func getStoredDaysSinceLastExposure() -> Int? {
        let today = currentDate()

        guard
            let lastExposureDate = lastStoredExposureReport()?.date,
            let dayCount = Calendar.current.dateComponents([.day], from: lastExposureDate, to: today).day
        else {
            return nil
        }

        return dayCount
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let exposureManager: ExposureManaging
    private let exposureDataController: ExposureDataControlling
    private let localPathProvider: LocalPathProviding
    private let configuration: ExposureConfiguration
    private let userNotificationController: UserNotificationControlling
    private let application: ApplicationControlling
    private let fileManager: FileManaging
    private let environmentController: EnvironmentControlling
    private let riskCalculationController: RiskCalculationControlling
    private let disposeBag = DisposeBag()
}
