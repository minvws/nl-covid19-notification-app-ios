/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation
import UIKit

private struct ExposureDetectionResult {
    let keySetHolder: ExposureKeySetHolder
    let exposureSummary: ExposureDetectionSummary?
    let processedCorrectly: Bool
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
        let exposureKeySets = getStoredKeySetsHolders()
            .filter { $0.processed == false }

        // convert all exposureKeySets into streams which emit detection reports
        let exposures = exposureKeySets.map {
            self.detectExposures(for: $0)
                .eraseToAnyPublisher()
        }

        // Combine all streams into an array of streams
        return Publishers.Sequence<[AnyPublisher<ExposureDetectionResult, ExposureDataError>], ExposureDataError>(sequence: exposures)
            // execute a single exposure at the same time
            .flatMap(maxPublishers: .max(1)) { $0 }
            // wait until all of them are done and collect them in an array again
            .collect()
            // persist exposure results
            .flatMap(persistResults(_:))
            // remove correctly processed sig/bin files from disk
            .handleEvents(receiveOutput: removeBlobs(forSuccessfulExposureResults:))
            // convert into exposure report and trigger a location notification
            .flatMap(convertResultsIntoExposureReportAndTriggerNotification(results:))
            // persist exposure report
            .flatMap(persist(exposureReport:))
            // update last processing date
            .flatMap { _ in self.updateLastProcessingDate() }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func getStoredKeySetsHolders() -> [ExposureKeySetHolder] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []
    }

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

    /// Returns ExposureDetectionResult in case of a success, or in case of an error that's
    /// not related to the framework's inactiveness. When an error is thrown from here exposure detection
    /// should be stopped until the user enables the framework
    private func detectExposures(for keySetHolder: ExposureKeySetHolder) -> AnyPublisher<ExposureDetectionResult, ExposureDataError> {
        return Deferred {
            Future { promise in
                if self.verifyLocalFileUrl(forKeySetsHolder: keySetHolder) == false {
                    // mark it as processed incorrectly to remove it from disk - will be downloaded again
                    // next time
                    let result = ExposureDetectionResult(keySetHolder: keySetHolder,
                                                         exposureSummary: nil,
                                                         processedCorrectly: false)
                    promise(.success(result))
                    return
                }

                let diagnosisKeyURLs = [keySetHolder.signatureFileUrl, keySetHolder.binaryFileUrl]

                self.exposureManager.detectExposures(configuration: self.configuration,
                                                     diagnosisKeyURLs: diagnosisKeyURLs) { result in
                    switch result {
                    case let .success(summary):
                        promise(.success(ExposureDetectionResult(keySetHolder: keySetHolder,
                                                                 exposureSummary: summary,
                                                                 processedCorrectly: true)))
                    case let .failure(error):
                        switch error {
                        case .bluetoothOff, .disabled, .notAuthorized, .restricted:
                            promise(.failure(error.asExposureDataError))
                        case .internalTypeMismatch:
                            promise(.failure(.internalError))
                        default:
                            promise(.success(ExposureDetectionResult(keySetHolder: keySetHolder,
                                                                     exposureSummary: nil,
                                                                     processedCorrectly: false)))
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func persistResults(_ results: [ExposureDetectionResult]) -> AnyPublisher<[ExposureDetectionResult], ExposureDataError> {
        return Deferred {
            Future { promise in
                let selectResult: (ExposureKeySetHolder) -> ExposureDetectionResult? = { holder in
                    return results.first { result in result.keySetHolder.identifier == holder.identifier }
                }

                self.storageController.requestExclusiveAccess { storageController in
                    let storedKeySetHolders = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []
                    var keySetHolders: [ExposureKeySetHolder] = []

                    storedKeySetHolders.forEach { keySetHolder in
                        guard let result = selectResult(keySetHolder) else {
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
                        promise(.success(results))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func removeBlobs(forSuccessfulExposureResults exposureResults: [ExposureDetectionResult]) {
        exposureResults
            .filter { $0.processedCorrectly }
            .forEach { result in
                try? FileManager.default.removeItem(at: result.keySetHolder.signatureFileUrl)
                try? FileManager.default.removeItem(at: result.keySetHolder.binaryFileUrl)
            }
    }

    private func selectLastSummaryFrom(results: [ExposureDetectionResult]) -> ExposureDetectionSummary? {
        // filter out unprocessed results
        let summaries = results
            .filter { $0.processedCorrectly }
            .compactMap { $0.exposureSummary }
            .filter { $0.daysSinceLastExposure > 0 }

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

    private func convertResultsIntoExposureReportAndTriggerNotification(results: [ExposureDetectionResult]) -> AnyPublisher<ExposureReport?, ExposureDataError> {

        hasAccessToShowLocalNotification
            .setFailureType(to: ExposureDataError.self)
            .flatMap { (hasAccessToShowLocalNotification: Bool) -> AnyPublisher<ExposureReport?, ExposureDataError> in
                if hasAccessToShowLocalNotification {
                    // no need to call API to get ExposureInformations, show local notification and move on
                    guard let latestSummary = self.selectLastSummaryFrom(results: results) else {
                        return Just(nil)
                            .setFailureType(to: ExposureDataError.self)
                            .eraseToAnyPublisher()
                    }

                    // calculate exposure date
                    let calendar = Calendar(identifier: .gregorian)
                    guard let exposureDate = calendar.date(byAdding: .day, value: -latestSummary.daysSinceLastExposure, to: Date()) else {
                        return Just(nil)
                            .setFailureType(to: ExposureDataError.self)
                            .eraseToAnyPublisher()
                    }

                    let exposureReport = ExposureReport(date: exposureDate, duration: nil)

                    // show notification
                    self.showLocalPushNotification(for: exposureReport)

                    return Just(exposureReport)
                        .setFailureType(to: ExposureDataError.self)
                        .eraseToAnyPublisher()
                }

                // no access to local notifications, call the framework to show a notification
                let summaries = results
                    .map { $0.exposureSummary }
                    .compactMap { $0 }
                    .filter { $0.daysSinceLastExposure > 0 }

                return self
                    .getExposureInformations(forSummaries: summaries,
                                             userExplanation: Localization.string(for: "exposure.notification.userExplanation"))
                    .map { (exposureInformation) -> ExposureReport? in
                        guard let exposureInformation = exposureInformation else {
                            return nil
                        }

                        return ExposureReport(date: exposureInformation.date,
                                              duration: exposureInformation.duration)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func getExposureInformations(forSummaries summaries: [ExposureDetectionSummary], userExplanation: String) -> AnyPublisher<ExposureInformation?, ExposureDataError> {
        let exposureChecks = summaries.map { summary in
            self.getExposureInformations(forSummary: summary, userExplanation: userExplanation)
        }

        return Publishers.Sequence<[AnyPublisher<[ExposureInformation]?, ExposureDataError>], ExposureDataError>(sequence: exposureChecks)
            .flatMap(maxPublishers: .max(1)) { $0 }
            .first { exposureInformations in (exposureInformations?.isEmpty ?? true) == false }
            .map(self.getLastExposureInformation(for:))
            .eraseToAnyPublisher()
    }

    private func getExposureInformations(forSummary summary: ExposureDetectionSummary, userExplanation: String) -> AnyPublisher<[ExposureInformation]?, ExposureDataError> {
        return Deferred {
            Future<[ExposureInformation]?, ExposureDataError> { promise in
                self.exposureManager
                    .getExposureInfo(summary: summary,
                                     userExplanation: userExplanation) { infos, error in
                        if let error = error {
                            promise(.failure(error.asExposureDataError))
                            return
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            promise(.success(infos))
                        }
                    }
                    .resume()
            }
            .subscribe(on: DispatchQueue.main)
        }
        .eraseToAnyPublisher()
    }

    private func getLastExposureInformation(for informations: [ExposureInformation]?) -> ExposureInformation? {
        guard let informations = informations else { return nil }

        let isNewer: (ExposureInformation, ExposureInformation) -> Bool = { first, second in
            return second.date > first.date
        }

        return informations.sorted(by: isNewer).last
    }

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

    private func updateLastProcessingDate() -> AnyPublisher<(), ExposureDataError> {
        return Deferred {
            Future { promise in
                self.storageController.requestExclusiveAccess { storageController in
                    let date: Date

                    if let storedDate = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureProcessingDate) {
                        date = storedDate
                    } else {
                        date = Date()
                    }

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

    private var hasAccessToShowLocalNotification: AnyPublisher<Bool, Never> {
        return Future { promise in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                promise(.success(settings.authorizationStatus == .authorized))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func showLocalPushNotification(for exposureReport: ExposureReport) {
//        let content = UNMutableNotificationContent()
//        content.title = "Local Notification"
//        content.body = "The body of the message which was scheduled from the Developer Menu"
//        content.sound = UNNotificationSound.default
//        content.badge = 0
//
//        let date = Date(timeIntervalSinceNow: 5)
//        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
//        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
//
//        let identifier = "Local Notification"
//        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
//
//        let unc = UNUserNotificationCenter.current()
//        unc.add(request) { error in
//            if let error = error {
//                print("🔥 Error \(error.localizedDescription)")
//            }
//        }
//        hide()
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let exposureManager: ExposureManaging
    private let configuration: ExposureConfiguration
}
