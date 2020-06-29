/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation
import UIKit

private struct ExposureKeySetDetectionResult {
    let keySetHolder: ExposureKeySetHolder
    let exposureSummary: ExposureDetectionSummary?
    let processedCorrectly: Bool
    let exposureReport: ExposureReport?
}

private struct ExposureDetectionResult {
    let keySetDetectionResults: [ExposureKeySetDetectionResult]
    let exposureSummary: ExposureDetectionSummary?
}

struct ExposureReport: Codable {
    let date: Date
    let duration: TimeInterval?
}

final class ProcessExposureKeySetsDataOperation: ExposureDataOperation {

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         exposureManager: ExposureManaging,
         configuration: ExposureConfiguration) {
        self.networkController = networkController
        self.storageController = storageController
        self.exposureManager = exposureManager
        self.configuration = configuration
    }

    func execute() -> AnyPublisher<(), ExposureDataError> {
        // get all keySets that have not been processed before
        let exposureKeySets = getStoredKeySetsHolders()
            .filter { $0.processed == false }

        // convert all exposureKeySets into streams which emit detection reports
        let exposures = exposureKeySets.map {
            self.detectExposures(for: $0)
                .eraseToAnyPublisher()
        }

        // Combine all streams into an array of streams
        return Publishers.Sequence<[AnyPublisher<ExposureKeySetDetectionResult, ExposureDataError>], ExposureDataError>(sequence: exposures)
            // execute them one by one
            .flatMap(maxPublishers: .max(1)) { $0 }
            // wait until all of them are done and collect them in an array again
            .collect()
            // batch detect the correctly processed results to get a single exposureSummary
            .flatMap(self.batchDetectExposures(for:))
            // persist keySetHolders in local storage to remember which ones have been processed correctly
            .flatMap(self.persistResult(_:))
            // create an exposureReport and trigger a local notification
            .flatMap(self.createReportAndTriggerNotification(forResult:))
            // remove all blobs for all keySetHolders - successful ones are processed and
            // should not be processed again. Failed ones should be downloaded again and
            // have already been removed from the list of keySetHolders in localStorage by persistResult(_:)
            .handleEvents(receiveOutput: removeBlobs(forResult:))
            // remove the exposureDetectionResult and return only the ExposureReport
            .map { value in value.1 }
            // persist the ExposureReport
            .flatMap(self.persist(exposureReport:))
            // update last processing date
            .flatMap { _ in self.updateLastProcessingDate() }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    /// Retrieves all stores keySetHolders from local storage
    private func getStoredKeySetsHolders() -> [ExposureKeySetHolder] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []
    }

    /// Verifies whether the KeySetHolder URLs point to valid files
    private func verifyLocalFileUrl(forKeySetsHolder keySetHolder: ExposureKeySetHolder) -> Bool {
        var isDirectory = ObjCBool(booleanLiteral: false)

        // verify export.sig and export.bin are present
        guard FileManager.default.fileExists(atPath: keySetHolder.signatureFileUrl.path, isDirectory: &isDirectory), isDirectory.boolValue == false else {
            return false
        }

        guard FileManager.default.fileExists(atPath: keySetHolder.binaryFileUrl.path, isDirectory: &isDirectory), isDirectory.boolValue == false else {
            return false
        }

        return true
    }

    /// Batch processes the previous results to result in a single exposure summary.
    /// Will filter out unsuccessfully processed results before batch processing them
    private func batchDetectExposures(for previousResults: [ExposureKeySetDetectionResult]) -> AnyPublisher<ExposureDetectionResult, ExposureDataError> {
        return Deferred {
            return Future { promise in
                // combine all urls into a single collection
                let urls = previousResults
                    .filter { result in result.processedCorrectly }
                    .flatMap { result in [result.keySetHolder.signatureFileUrl, result.keySetHolder.binaryFileUrl] }

                guard urls.count > 0 else {
                    let result = ExposureDetectionResult(keySetDetectionResults: previousResults,
                                                         exposureSummary: nil)

                    promise(.success(result))
                    return
                }

                // detect exposures
                self.exposureManager.detectExposures(configuration: self.configuration,
                                                     diagnosisKeyURLs: urls) { result in
                    switch result {
                    case let .success(summary):
                        let result = ExposureDetectionResult(keySetDetectionResults: previousResults,
                                                             exposureSummary: summary)
                        promise(.success(result))
                    case let .failure(error):
                        switch error {
                        case .bluetoothOff, .disabled, .notAuthorized, .restricted:
                            promise(.failure(error.asExposureDataError))
                        case .internalTypeMismatch:
                            promise(.failure(.internalError))
                        default:
                            let result = ExposureDetectionResult(keySetDetectionResults: previousResults,
                                                                 exposureSummary: nil)
                            promise(.success(result))
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Returns ExposureKeySetDetectionResult in case of a success, or in case of an error that's
    /// not related to the framework's inactiveness. When an error is thrown from here exposure detection
    /// should be stopped until the user enables the framework
    private func detectExposures(for keySetHolder: ExposureKeySetHolder) -> AnyPublisher<ExposureKeySetDetectionResult, ExposureDataError> {
        return Deferred {
            Future { promise in
                if self.verifyLocalFileUrl(forKeySetsHolder: keySetHolder) == false {
                    // mark it as processed incorrectly - will be downloaded again
                    // next time
                    let result = ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
                                                               exposureSummary: nil,
                                                               processedCorrectly: false,
                                                               exposureReport: nil)
                    promise(.success(result))
                    return
                }

                let diagnosisKeyURLs = [keySetHolder.signatureFileUrl, keySetHolder.binaryFileUrl]

                self.exposureManager.detectExposures(configuration: self.configuration,
                                                     diagnosisKeyURLs: diagnosisKeyURLs) { result in
                    switch result {
                    case let .success(summary):
                        promise(.success(ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
                                                                       exposureSummary: summary,
                                                                       processedCorrectly: true,
                                                                       exposureReport: nil)))
                    case let .failure(error):
                        switch error {
                        case .bluetoothOff, .disabled, .notAuthorized, .restricted:
                            promise(.failure(error.asExposureDataError))
                        case .internalTypeMismatch:
                            promise(.failure(.internalError))
                        default:
                            promise(.success(ExposureKeySetDetectionResult(keySetHolder: keySetHolder,
                                                                           exposureSummary: nil,
                                                                           processedCorrectly: false,
                                                                           exposureReport: nil)))
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Updates the local keySetHolder storage with the latest results
    private func persistResult(_ result: ExposureDetectionResult) -> AnyPublisher<ExposureDetectionResult, ExposureDataError> {
        return Deferred {
            Future { promise in
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

                        if result.processedCorrectly {
                            // only store correctly processed results - forget about incorrectly processed ones
                            // and try to download those again next time
                            keySetHolders.append(ExposureKeySetHolder(identifier: keySetHolder.identifier,
                                                                      signatureFileUrl: keySetHolder.signatureFileUrl,
                                                                      binaryFileUrl: keySetHolder.binaryFileUrl,
                                                                      processed: true,
                                                                      creationDate: keySetHolder.creationDate))
                        }
                    }

                    storageController.store(object: keySetHolders,
                                            identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) { _ in
                        promise(.success(result))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Removes binary files for the keySetHolders of the exposureDetectionResult
    private func removeBlobs(forResult exposureResult: (ExposureDetectionResult, ExposureReport?)) {
        let keySetHolders = exposureResult.0.keySetDetectionResults.map { $0.keySetHolder }

        keySetHolders.forEach { keySetHolder in
            try? FileManager.default.removeItem(at: keySetHolder.signatureFileUrl)
            try? FileManager.default.removeItem(at: keySetHolder.binaryFileUrl)
        }
    }

    /// Select a most recent exposure summary
    private func selectLastSummaryFrom(result: ExposureDetectionResult) -> ExposureDetectionSummary? {
        // filter out unprocessed results
        let summaries = result
            .keySetDetectionResults
            .filter { $0.processedCorrectly }
            .compactMap { $0.exposureSummary }
            .filter { $0.matchedKeyCount > 0 }

        // find most recent exposure day
        guard let mostRecentDaysSinceLastExposure = summaries
            .sorted(by: { $1.daysSinceLastExposure < $0.daysSinceLastExposure })
            .last?
            .daysSinceLastExposure
        else {
            return nil
        }

        // take only most recent exposures and select first (doesn't matter which one)
        return summaries
            .filter { $0.daysSinceLastExposure == mostRecentDaysSinceLastExposure }
            .first
    }

    /// Creates the final ExposureReport and triggers a local notification.
    /// If no push notification permission is given the EN framework is used to trigger a local notification.
    /// If push notification permission is given a local notification is scheduled
    private func createReportAndTriggerNotification(forResult result: ExposureDetectionResult) -> AnyPublisher<(ExposureDetectionResult, ExposureReport?), ExposureDataError> {

        // figure out whether push notification permission was given
        hasAccessToShowLocalNotification
            .setFailureType(to: ExposureDataError.self)
            .flatMap { (hasAccessToShowLocalNotification: Bool) -> AnyPublisher<(ExposureDetectionResult, ExposureReport?), ExposureDataError> in
                if hasAccessToShowLocalNotification {
                    // user has given permission for push notifications
                    // no need to call API to get ExposureInformations, show local notification and move on

                    // select a most recent summary
                    guard let latestSummary = self.selectLastSummaryFrom(result: result) else {
                        return Just((result, nil))
                            .setFailureType(to: ExposureDataError.self)
                            .eraseToAnyPublisher()
                    }

                    // calculate exposure date
                    let calendar = Calendar.current
                    guard let exposureDate = calendar.date(byAdding: .day, value: -latestSummary.daysSinceLastExposure, to: Date()) else {
                        return Just((result, nil))
                            .setFailureType(to: ExposureDataError.self)
                            .eraseToAnyPublisher()
                    }

                    let exposureReport = ExposureReport(date: exposureDate, duration: nil)

                    // show notification
                    self.showLocalPushNotification(for: exposureReport)

                    return Just((result, exposureReport))
                        .setFailureType(to: ExposureDataError.self)
                        .eraseToAnyPublisher()
                }

                // no access to local notifications, call the framework to show a notification using
                // the overall exposureSummary
                guard let summary = result.exposureSummary else {
                    return Just((result, nil))
                        .setFailureType(to: ExposureDataError.self)
                        .eraseToAnyPublisher()
                }

                return self
                    .getExposureInformations(forSummary: summary,
                                             userExplanation: Localization.string(for: "exposure.notification.userExplanation"))
                    .map { (exposureInformations) -> (ExposureDetectionResult, ExposureReport?) in
                        // get most recent exposureInformation
                        guard let exposureInformation = self.getLastExposureInformation(for: exposureInformations) else {
                            return (result, nil)
                        }

                        let exposureReport = ExposureReport(date: exposureInformation.date,
                                                            duration: exposureInformation.duration)

                        return (result, exposureReport)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// Asks the EN framework for more information about the exposure summary which
    /// triggers a local notification if the exposure was risky enough (according to the configuration and
    /// the rules of the EN framework)
    private func getExposureInformations(forSummary summary: ExposureDetectionSummary?, userExplanation: String) -> AnyPublisher<[ExposureInformation]?, ExposureDataError> {
        guard let summary = summary else {
            return Just(nil).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }

        return Deferred {
            Future<[ExposureInformation]?, ExposureDataError> { promise in
                self.exposureManager
                    .getExposureInfo(summary: summary,
                                     userExplanation: userExplanation) { infos, error in
                        if let error = error {
                            promise(.failure(error.asExposureDataError))
                            return
                        }

                        promise(.success(infos))
                    }
            }
            .subscribe(on: DispatchQueue.main)
        }
        .eraseToAnyPublisher()
    }

    /// Returns the exposureInformation with the most recent date
    private func getLastExposureInformation(for informations: [ExposureInformation]?) -> ExposureInformation? {
        guard let informations = informations else { return nil }

        let isNewer: (ExposureInformation, ExposureInformation) -> Bool = { first, second in
            return second.date > first.date
        }

        return informations.sorted(by: isNewer).last
    }

    /// Stores the exposureReport in local storage (which triggers the 'notified' state)
    private func persist(exposureReport: ExposureReport?) -> AnyPublisher<(), ExposureDataError> {
        return Deferred {
            Future { promise in
                guard let exposureReport = exposureReport else {
                    promise(.success(()))
                    return
                }

                self.storageController.requestExclusiveAccess { storageController in
                    let lastExposureReport = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureReport)

                    if let lastExposureReport = lastExposureReport, lastExposureReport.date > exposureReport.date {
                        // already stored a newer report, ignore this one
                        promise(.success(()))
                    } else {
                        // store the new report
                        storageController.store(object: exposureReport,
                                                identifiedBy: ExposureDataStorageKey.lastExposureReport) { _ in
                            promise(.success(()))
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Updates the date when this operation has last run
    private func updateLastProcessingDate() -> AnyPublisher<(), ExposureDataError> {
        return Deferred {
            Future { promise in
                self.storageController.requestExclusiveAccess { storageController in
                    let date = Date()

                    storageController.store(object: date,
                                            identifiedBy: ExposureDataStorageKey.lastExposureProcessingDate,
                                            completion: { _ in
                                                promise(.success(()))
                    })
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Returns whether a user has given permission to trigger push notifications
    private var hasAccessToShowLocalNotification: AnyPublisher<Bool, Never> {
        // Hardcode to false for now - Always let the getExposureInfo call generate
        // the local notification
        return Just(false).eraseToAnyPublisher()

//        return Future { promise in
//            UNUserNotificationCenter.current().getNotificationSettings { settings in
//                promise(.success(settings.authorizationStatus == .authorized))
//            }
//        }
//        .receive(on: DispatchQueue.main)
//        .eraseToAnyPublisher()
    }

    /// Schedules a local notification for the given exposureReport
    private func showLocalPushNotification(for exposureReport: ExposureReport) {
        // TODO: Implement properly
        let content = UNMutableNotificationContent()
        content.title = "Local Notification"
        content.body = "The body of the message which was scheduled from the Developer Menu"
        content.sound = UNNotificationSound.default
        content.badge = 0

        let date = Date(timeIntervalSinceNow: 1)
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = "Local Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        let unc = UNUserNotificationCenter.current()
        unc.add(request) { error in
            if let error = error {
                print("🔥 Error \(error.localizedDescription)")
            }
        }
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let exposureManager: ExposureManaging
    private let configuration: ExposureConfiguration
}
