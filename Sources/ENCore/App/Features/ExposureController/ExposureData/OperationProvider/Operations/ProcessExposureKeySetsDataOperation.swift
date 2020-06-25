/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

private struct ExposureDetectionResult {
    let keySetHolder: ExposureKeySetHolder
    let exposureSummary: ExposureDetectionSummary?
    let processedCorrectly: Bool
}

struct ExposureReport: Codable {
    let date: Date
    let duration: TimeInterval
}

final class ProcessExposureKeySetsDataOperation: ExposureDataOperation {

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         exposureManager: ExposureManaging) {
        self.networkController = networkController
        self.storageController = storageController
        self.exposureManager = exposureManager
    }

    func execute() -> AnyPublisher<(), ExposureDataError> {
        let exposureKeySets = getStoredKeySetsHolders()
            .filter { $0.processed == false }

        let exposures = exposureKeySets.map {
            self.detectExposures(for: $0)
                .eraseToAnyPublisher()
        }

        return Publishers.Sequence<[AnyPublisher<ExposureDetectionResult, ExposureDataError>], ExposureDataError>(sequence: exposures)
            .flatMap(maxPublishers: .max(1)) { $0 }
            .collect()
            .flatMap(persistResults(_:))
            .handleEvents(receiveOutput: removeBlobs(forSuccessfulExposureResults:))
            .map(selectFrom(results:))
            .flatMap { summary in
                self.getExposureInformations(for: summary, userExplanation: Localization.string(for: "exposure.notification.userExplanation"))
            }
            .flatMap(persist(exposure:))
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

                self.exposureManager.detectExposures(diagnosisKeyURLs: diagnosisKeyURLs) { result in
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

    private func selectFrom(results: [ExposureDetectionResult]) -> ExposureDetectionSummary? {
        let isNewer: (ExposureDetectionSummary, ExposureDetectionSummary) -> Bool = { first, second in
            return second.daysSinceLastExposure < first.daysSinceLastExposure
        }

        return results
            .filter { $0.processedCorrectly }
            .compactMap { $0.exposureSummary }
            .filter { $0.matchedKeyCount > 0 }
            .sorted(by: isNewer)
            .last
    }

    private func getExposureInformations(for summary: ExposureDetectionSummary?, userExplanation: String) -> AnyPublisher<ExposureInformation?, ExposureDataError> {
        return Deferred {
            Future { promise in
                guard let summary = summary else {
                    promise(.success(nil))
                    return
                }

                self.exposureManager.getExposureInfo(summary: summary,
                                                     userExplanation: userExplanation)
                { informations, error in
                    if let error = error?.asExposureDataError {
                        promise(.failure(error))
                        return
                    }

                    let information = self.getLastExposureInformation(for: informations ?? [])
                    promise(.success(information))
                }
                .resume()
            }
        }
        .eraseToAnyPublisher()
    }

    private func getLastExposureInformation(for informations: [ExposureInformation]) -> ExposureInformation? {
        let isNewer: (ExposureInformation, ExposureInformation) -> Bool = { first, second in
            return second.date > first.date
        }

        return informations.sorted(by: isNewer).last
    }

    private func persist(exposure: ExposureInformation?) -> AnyPublisher<(), ExposureDataError> {
        return Deferred {
            Future { promise in
                guard let exposure = exposure else {
                    promise(.success(()))
                    return
                }

                let exposureReport = ExposureReport(date: exposure.date,
                                                    duration: exposure.duration)

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

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let exposureManager: ExposureManaging
}
