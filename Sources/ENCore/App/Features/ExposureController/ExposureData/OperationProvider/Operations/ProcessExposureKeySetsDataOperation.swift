/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation
import RxSwift
import UIKit

private struct ExposureKeySetDetectionResult {
    let keySetHolder: ExposureKeySetHolder
    let processDate: Date?
    let isValid: Bool
}

private struct ExposureDetectionResult {
    let keySetDetectionResults: [ExposureKeySetDetectionResult]
    let exposureSummary: ExposureDetectionSummary?
    let exposureReport: ExposureReport?
}

struct ExposureReport: Codable {
    let date: Date
}

#if USE_DEVELOPER_MENU || DEBUG

    struct ProcessExposureKeySetsDataOperationOverrides {
        static var respectMaximumDailyKeySets = true
    }

#endif
protocol ProcessExposureKeySetsDataOperationProtocol {
    func execute() -> Observable<()>
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

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         exposureManager: ExposureManaging,
         exposureKeySetsStorageUrl: URL,
         configuration: ExposureConfiguration,
         userNotificationCenter: UserNotificationCenter,
         application: ApplicationControlling,
         fileManager: FileManaging,
         environmentController: EnvironmentControlling) {
        self.networkController = networkController
        self.storageController = storageController
        self.exposureManager = exposureManager
        self.exposureKeySetsStorageUrl = exposureKeySetsStorageUrl
        self.configuration = configuration
        self.userNotificationCenter = userNotificationCenter
        self.application = application
        self.fileManager = fileManager
        self.environmentController = environmentController
    }

    func execute() -> Observable<()> {
        self.logDebug("--- START PROCESSING KEYSETS ---")

        // get all keySetHolders that have not been processed before
        let exposureKeySetHolders = getStoredKeySetsHolders()
            // filter out already processed ones
            .filter { $0.processed == false }

        if exposureKeySetHolders.count > 0 {
            logDebug("Processing \(exposureKeySetHolders.count) KeySets: \(exposureKeySetHolders.map { $0.identifier }.joined(separator: "\n"))")
        } else {
            // keep processing to make sure lastProcessDate is updated
            logDebug("No additional keysets to process")
        }

        // Batch detect exposures
        return detectExposures(for: exposureKeySetHolders)
            // persist keySetHolders in local storage to remember which ones have been processed correctly
            .flatMap(self.persistResult(_:))
            // create an exposureReport and trigger a local notification
            .flatMap(self.createReportAndTriggerNotification(forResult:))
            // persist the ExposureReport
            .flatMap(self.persist(exposureReport:))
            // update last processing date
            .flatMap(self.updateLastProcessingDate)
            // remove all blobs for all keySetHolders - successful ones are processed and
            // should not be processed again. Failed ones should be downloaded again and
            // have already been removed from the list of keySetHolders in localStorage by persistResult(_:)
            .do(onNext: removeBlobs(forResult:))
            // ignore result
            .map { _ in () }
            .do(onCompleted: {
                self.logDebug("--- END PROCESSING KEYSETS ---")
            })
            .share()
    }

    // MARK: - Private

    /// Retrieves all stores keySetHolders from local storage
    private func getStoredKeySetsHolders() -> [ExposureKeySetHolder] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []
    }

    /// Verifies whether the KeySetHolder URLs point to valid files
    private func verifyLocalFileUrl(forKeySetsHolder keySetHolder: ExposureKeySetHolder) -> Bool {
        var isDirectory = ObjCBool(booleanLiteral: false)

        // verify whether sig and bin files are present
        guard let sigPath = signatureFileUrl(forKeySetHolder: keySetHolder)?.path,
            fileManager.fileExists(atPath: sigPath,
                                   isDirectory: &isDirectory), isDirectory.boolValue == false else {
            return false
        }

        guard let binPath = binaryFileUrl(forKeySetHolder: keySetHolder)?.path,
            fileManager.fileExists(atPath: binPath,
                                   isDirectory: &isDirectory), isDirectory.boolValue == false else {
            return false
        }

        return true
    }

    /// Returns ExposureKeySetDetectionResult in case of a success, or in case of an error that's
    /// not related to the framework's inactiveness. When an error is thrown from here exposure detection
    /// should be stopped until the user enables the framework
    private func detectExposures(for keySetHolders: [ExposureKeySetHolder]) -> Observable<ExposureDetectionResult> {

        // filter out keysets with missing local files
        let validKeySetHolders = keySetHolders.filter(self.verifyLocalFileUrl(forKeySetsHolder:))
        let invalidKeySetHolders = keySetHolders.filter { keySetHolder in
            !validKeySetHolders.contains { $0.identifier == keySetHolder.identifier }
        }

        logDebug("Invalid KeySetHolders: \(invalidKeySetHolders.map { $0.identifier })")
        logDebug("Valid KeySetHolders: \(validKeySetHolders.map { $0.identifier })")

        // create results for the keySetHolders with missing local files
        let invalidKeySetHolderResults = invalidKeySetHolders.map { keySetHolder in
            return ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
                                                 processDate: nil,
                                                 isValid: false)
        }

        // Determine if we are limited by the number of daily API calls or KeySets
        let applicationIsInBackground = application.isInBackground
        let numberOfDailyAPICallsLeft = getNumberOfDailyAPICallsLeft(inBackground: applicationIsInBackground)
        let numberOfDailyKeySetsLeft = getNumberOfDailyKeySetsLeft()

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

            return .just(ExposureDetectionResult(keySetDetectionResults: validKeySetHolderResults + invalidKeySetHolderResults,
                                                 exposureSummary: nil,
                                                 exposureReport: nil))
        }

        let diagnosisKeyUrls = keySetHoldersToProcess.flatMap { (keySetHolder) -> [URL] in
            if let sigFile = signatureFileUrl(forKeySetHolder: keySetHolder), let binFile = binaryFileUrl(forKeySetHolder: keySetHolder) {
                return [sigFile, binFile]
            }
            return []
        }

        logDebug("Detect exposures for \(keySetHoldersToProcess.count) keySets: \(keySetHoldersToProcess.map { $0.identifier })")

        return updateNumberOfApiCallsMade(inBackground: applicationIsInBackground)
            .flatMap { _ in self.detectExposures(diagnosisKeyUrls: diagnosisKeyUrls, invalidKeySetHolderResults: invalidKeySetHolderResults, keySetHoldersToProcess: keySetHoldersToProcess) }
    }

    private func detectExposures(diagnosisKeyUrls: [URL],
                                 invalidKeySetHolderResults: [ExposureKeySetDetectionResult],
                                 keySetHoldersToProcess: [ExposureKeySetHolder]) -> Observable<ExposureDetectionResult> {

        return .create { observer in

            self.logDebug("Detecting exposures for \(diagnosisKeyUrls.count) diagnosisKeyUrls")

            self.exposureManager.detectExposures(configuration: self.configuration,
                                                 diagnosisKeyURLs: diagnosisKeyUrls) { result in
                switch result {
                case let .success(summary):
                    self.logDebug("Successfully detected exposures: \(String(describing: summary))")

                    let validKeySetHolderResults = keySetHoldersToProcess.map { keySetHolder in
                        return ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
                                                             processDate: Date(),
                                                             isValid: true)
                    }

                    let keySetHolderResults = invalidKeySetHolderResults + validKeySetHolderResults
                    let result = ExposureDetectionResult(keySetDetectionResults: keySetHolderResults,
                                                         exposureSummary: summary,
                                                         exposureReport: nil)

                    observer.onNext(result)
                    observer.onCompleted()

                case let .failure(error):
                    self.logDebug("Failure when detecting exposures: \(error)")

                    switch error {
                    case .bluetoothOff, .disabled, .notAuthorized, .restricted:
                        observer.onError(error.asExposureDataError)
                    case .internalTypeMismatch:
                        observer.onError(ExposureDataError.internalError)
                    case .rateLimited:
                        observer.onError(ExposureDataError.internalError)
                    default:
                        // something else is going wrong with exposure detection
                        // mark all keysets as invalid so they will be redownloaded again
                        let validKeySetHolderResults = keySetHoldersToProcess.map { keySetHolder in
                            return ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
                                                                 processDate: nil,
                                                                 isValid: false)
                        }

                        let keySetHolderResults = invalidKeySetHolderResults + validKeySetHolderResults
                        let result = ExposureDetectionResult(keySetDetectionResults: keySetHolderResults,
                                                             exposureSummary: nil,
                                                             exposureReport: nil)

                        observer.onNext(result)
                        observer.onCompleted()
                    }
                }
            }

            return Disposables.create()
        }
    }

    /// Updates the local keySetHolder storage with the latest results
    private func persistResult(_ result: ExposureDetectionResult) -> Observable<ExposureDetectionResult> {
        return .create { (observer) -> Disposable in

            let selectKeySetDetectionResult: (ExposureKeySetHolder) -> ExposureKeySetDetectionResult? = { keySetHolder in
                // find result that belongs to the keySetHolder
                result.keySetDetectionResults.first { result in result.keySetHolder.identifier == keySetHolder.identifier }
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
                        observer.onError(ExposureDataError.internalError)
                    } else {
                        observer.onNext(result)
                        observer.onCompleted()
                    }
                }
            }

            return Disposables.create()
        }
    }

    /// Removes binary files for processed or invalid keySetHolders
    private func removeBlobs(forResult exposureResult: (ExposureDetectionResult, ExposureReport?)) {
        let keySetHolders = exposureResult.0
            .keySetDetectionResults
            .filter { $0.processDate != nil || $0.isValid == false }
            .map { $0.keySetHolder }

        keySetHolders.forEach { keySetHolder in
            if let sigFileURL = signatureFileUrl(forKeySetHolder: keySetHolder) {
                try? fileManager.removeItem(at: sigFileURL)
            }

            if let binFileURL = binaryFileUrl(forKeySetHolder: keySetHolder) {
                try? fileManager.removeItem(at: binFileURL)
            }
        }
    }

    private func getNumberOfProcessedKeySetsInLast24Hours() -> Int {
        guard let cutOffDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) else {
            return 0
        }

        let wasProcessedInLast24h: (ExposureKeySetHolder) -> Bool = { keySetHolder in
            guard let processDate = keySetHolder.processDate else {
                return false
            }

            return processDate > cutOffDate
        }

        return getStoredKeySetsHolders()
            .filter(wasProcessedInLast24h)
            .count
    }

    func updateNumberOfApiCallsMade(inBackground: Bool) -> Observable<()> {
        return .create { (observer) -> Disposable in
            self.storageController.requestExclusiveAccess { storageController in
                let storageKey: CodableStorageKey<[Date]> = inBackground ? ExposureDataStorageKey.exposureApiBackgroundCallDates : ExposureDataStorageKey.exposureApiCallDates
                var calls = storageController.retrieveObject(identifiedBy: storageKey) ?? []

                calls = [Date()] + calls
                self.logDebug("Most recent API calls \(calls)")

                let maximumNumberOfAPICalls = inBackground ? self.maximumDailyBackgroundExposureDetectionAPICalls : self.maximumDailyForegroundExposureDetectionAPICalls

                if calls.count > maximumNumberOfAPICalls {
                    calls = Array(calls.prefix(maximumNumberOfAPICalls))
                }

                storageController.store(object: calls, identifiedBy: storageKey) { error in
                    if error != nil {
                        observer.onError(ExposureDataError.internalError)
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            }

            return Disposables.create()
        }
    }

    private func getNumberOfExposureDetectionApiCallsInLast24Hours(inBackground: Bool = false) -> Int {
        let storageKey: CodableStorageKey<[Date]> = inBackground ? ExposureDataStorageKey.exposureApiBackgroundCallDates : ExposureDataStorageKey.exposureApiCallDates
        let apiCalls = storageController.retrieveObject(identifiedBy: storageKey) ?? []

        guard let cutOffDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) else {
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

        if environmentController.isiOS136orHigher {
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
        }

        logDebug("Number of API Calls (\(inBackground ? "in background" : "in foreground")) left today: \(numberOfCallsLeft)")

        return numberOfCallsLeft
    }

    private func getNumberOfDailyKeySetsLeft() -> Int {
        if environmentController.isiOS136orHigher {
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

        let numberOfKeySetsLeftToProcess = maximumDailyOfKeySetsToProcess - getNumberOfProcessedKeySetsInLast24Hours()
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

    /// Creates the final ExposureReport and triggers a local notification using the EN framework
    private func createReportAndTriggerNotification(forResult result: ExposureDetectionResult) -> Observable<(ExposureDetectionResult, ExposureReport?)> {

        guard let summary = result.exposureSummary else {
            logDebug("No summary to trigger notification for")
            return .just((result, nil))
        }

        guard summary.maximumRiskScore >= configuration.minimumRiskScope else {
            logDebug("Risk Score not high enough to see this as an exposure")
            return .just((result, nil))
        }

        if let daysSinceLastExposure = daysSinceLastExposure() {
            logDebug("Had previous exposure \(daysSinceLastExposure) days ago")

            if summary.daysSinceLastExposure >= daysSinceLastExposure {
                logDebug("Previous exposure was newer than new found exposure - skipping notification")
                return .just((result, nil))
            }
        }

        guard let date = Calendar.current.date(byAdding: .day, value: -summary.daysSinceLastExposure, to: Date()) else {
            logError("Error triggering notification for \(summary), could not create date")
            return .just((result, nil))
        }

        logDebug("Triggering notification for \(summary)")

        return notifyUserOfExposure(daysSinceLastExposure: summary.daysSinceLastExposure,
                                    exposureReport: (result, ExposureReport(date: date)))
    }

    private func notifyUserOfExposure(daysSinceLastExposure: Int,
                                      exposureReport value: (ExposureDetectionResult, ExposureReport?)) -> Observable<(ExposureDetectionResult, ExposureReport?)> {
        return .create { (observer) -> Disposable in

            self.userNotificationCenter.getAuthorizationStatus { status in
                guard status == .authorized else {
                    observer.onError(ExposureDataError.internalError)
                    return self.logError("Not authorized to post notifications")
                }

                let content = UNMutableNotificationContent()
                content.body = .exposureNotificationUserExplanation(.statusNotifiedDaysAgo(days: daysSinceLastExposure))
                content.sound = .default
                content.badge = 0

                let request = UNNotificationRequest(identifier: PushNotificationIdentifier.exposure.rawValue,
                                                    content: content,
                                                    trigger: nil)

                self.userNotificationCenter.add(request) { error in

                    if let error = error {
                        self.logError("Error posting notification: \(error.localizedDescription)")
                        observer.onError(ExposureDataError.internalError)
                        return
                    }

                    /// Store the unseen notification date, but only when the app is in the background
                    if self.application.isInBackground {
                        self.storageController.requestExclusiveAccess { storageController in
                            storageController.store(object: Date(),
                                                    identifiedBy: ExposureDataStorageKey.lastUnseenExposureNotificationDate) { error in
                                if error != nil {
                                    observer.onError(ExposureDataError.internalError)
                                } else {
                                    observer.onNext(value)
                                    observer.onCompleted()
                                }
                            }
                        }
                    } else {
                        observer.onNext(value)
                        observer.onCompleted()
                    }
                }
            }

            return Disposables.create()
        }
    }

    /// Stores the exposureReport in local storage (which triggers the 'notified' state)
    private func persist(exposureReport value: (ExposureDetectionResult, ExposureReport?)) -> Observable<(ExposureDetectionResult, ExposureReport?)> {
        return .create { (observer) -> Disposable in
            guard let exposureReport = value.1 else {
                observer.onNext(value)
                observer.onCompleted()
                return Disposables.create()
            }

            self.storageController.requestExclusiveAccess { storageController in
                let lastExposureReport = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureReport)

                if let lastExposureReport = lastExposureReport, lastExposureReport.date > exposureReport.date {
                    // already stored a newer report, ignore this one
                    observer.onNext(value)
                    observer.onCompleted()
                } else {
                    // store the new report
                    storageController.store(object: exposureReport,
                                            identifiedBy: ExposureDataStorageKey.lastExposureReport) { error in
                        if error != nil {
                            observer.onError(ExposureDataError.internalError)
                        } else {
                            observer.onNext(value)
                            observer.onCompleted()
                        }
                    }
                }
            }

            return Disposables.create()
        }
    }

    /// Updates the date when this operation has last run
    private func updateLastProcessingDate(_ value: (ExposureDetectionResult, ExposureReport?)) -> Observable<(ExposureDetectionResult, ExposureReport?)> {
        return .create { (observer) -> Disposable in

            self.storageController.requestExclusiveAccess { storageController in
                let date = Date()

                self.logDebug("Updating last process date to \(date)")

                storageController.store(object: date,
                                        identifiedBy: ExposureDataStorageKey.lastExposureProcessingDate,
                                        completion: { error in
                                            if error != nil {
                                                observer.onError(ExposureDataError.internalError)
                                            } else {
                                                observer.onNext(value)
                                                observer.onCompleted()
                                            }
                                        })
            }

            return Disposables.create()
        }
    }

    private func signatureFileUrl(forKeySetHolder keySetHolder: ExposureKeySetHolder) -> URL? {
        guard let signatureFilename = keySetHolder.signatureFilename else {
            return nil
        }

        return exposureKeySetsStorageUrl.appendingPathComponent(signatureFilename)
    }

    private func binaryFileUrl(forKeySetHolder keySetHolder: ExposureKeySetHolder) -> URL? {
        guard let binaryFilename = keySetHolder.binaryFilename else {
            return nil
        }

        return exposureKeySetsStorageUrl.appendingPathComponent(binaryFilename)
    }

    private func lastStoredExposureReport() -> ExposureReport? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureReport)
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

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let exposureManager: ExposureManaging
    private let exposureKeySetsStorageUrl: URL
    private let configuration: ExposureConfiguration
    private let userNotificationCenter: UserNotificationCenter
    private let application: ApplicationControlling
    private let fileManager: FileManaging
    private let environmentController: EnvironmentControlling
}
