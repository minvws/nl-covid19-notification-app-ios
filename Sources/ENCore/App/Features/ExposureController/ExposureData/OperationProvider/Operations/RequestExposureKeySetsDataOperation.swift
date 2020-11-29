/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation

struct ExposureKeySetHolder: Codable {
    let identifier: String
    let signatureFilename: String
    let binaryFilename: String
    let processDate: Date?
    let creationDate: Date

    var processed: Bool { processDate != nil }
}

final class RequestExposureKeySetsDataOperation: ExposureDataOperation, Logging {
    private let signatureFilename = "export.sig"
    private let binaryFilename = "export.bin"

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         localPathProvider: LocalPathProviding,
         exposureKeySetIdentifiers: [String]) {
        self.networkController = networkController
        self.storageController = storageController
        self.localPathProvider = localPathProvider
        self.exposureKeySetIdentifiers = exposureKeySetIdentifiers
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<(), ExposureDataError> {
        logDebug("--- START REQUESTING KEYSETS ---")

        let storedKeySetsHolders = getStoredKeySetsHolders()
        let identifiers = removeAlreadyDownloadedOrProcessedKeySetIdentifiers(from: exposureKeySetIdentifiers,
                                                                              storedKeySetsHolders: storedKeySetsHolders)

        guard identifiers.count > 0 else {
            logDebug("No additional key sets to download")
            logDebug("--- END REQUESTING KEYSETS ---")

            return Just(())
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        logDebug("Requesting Exposure KeySets: \(identifiers.joined(separator: "\n"))")

        // download remaining keysets
        let exposureKeySetStreams: [AnyPublisher<(String, URL), NetworkError>] = identifiers.map { identifier in
            self.networkController
                .fetchExposureKeySet(identifier: identifier)
                .eraseToAnyPublisher()
        }

        // schedule all downloads at once - the networking layer should limit the number of parallel
        // requests if necessary
        return Publishers.Sequence<[AnyPublisher<(String, URL), NetworkError>], NetworkError>(sequence: exposureKeySetStreams)
            .flatMap { $0 }
            .mapError { error in
                self.logError("RequestExposureKeySetsDataOperation Error: \(error)")
                return error.asExposureDataError
            }
            .collect()
            .flatMap(createKeySetHolders)
            .flatMap(storeDownloadedKeySetsHolders)
            .handleEvents(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        self.logDebug("Background: Exposure Notification Status Check Completed")
                    case .failure:
                        self.logDebug("Background: Exposure Notification Status Check Failed")
                    }

                    self.logDebug("--- END REQUESTING KEYSETS ---")
                },
                receiveCancel: { self.logDebug("--- REQUESTING KEYSETS CANCELLED ---") }
            )
            .share()
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func getStoredKeySetsHolders() -> [ExposureKeySetHolder] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []
    }

    private func removeAlreadyDownloadedOrProcessedKeySetIdentifiers(from identifiers: [String],
                                                                     storedKeySetsHolders: [ExposureKeySetHolder]) -> [String] {
        let isNotDownloadedOrProcessed: (String) -> Bool = { identifier in !storedKeySetsHolders.contains { $0.identifier == identifier } }
        return identifiers.filter(isNotDownloadedOrProcessed)
    }

    private func createKeySetHolders(forDownloadedKeySets keySets: [(String, URL)]) -> AnyPublisher<[ExposureKeySetHolder], ExposureDataError> {
        return Deferred {
            return Future<[ExposureKeySetHolder], ExposureDataError> { promise in
                guard let keySetStorageUrl = self.localPathProvider.path(for: .exposureKeySets) else {
                    promise(.failure(.internalError))
                    return
                }

                var keySetHolders: [ExposureKeySetHolder] = []

                keySets.forEach { keySet in
                    let (identifier, localUrl) = keySet
                    let srcSignatureUrl = localUrl.appendingPathComponent(self.signatureFilename)
                    let srcBinaryUrl = localUrl.appendingPathComponent(self.binaryFilename)

                    let dstSignatureFilename = [identifier, "sig"].joined(separator: ".")
                    let dstSignatureUrl = keySetStorageUrl.appendingPathComponent(dstSignatureFilename)
                    let dstBinaryFilename = [identifier, "bin"].joined(separator: ".")
                    let dstBinaryUrl = keySetStorageUrl.appendingPathComponent(dstBinaryFilename)

                    do {
                        if FileManager.default.fileExists(atPath: dstSignatureUrl.path) {
                            try FileManager.default.removeItem(atPath: dstSignatureUrl.path)
                        }

                        if FileManager.default.fileExists(atPath: dstBinaryUrl.path) {
                            try FileManager.default.removeItem(atPath: dstBinaryUrl.path)
                        }

                        try FileManager.default.moveItem(at: srcSignatureUrl, to: dstSignatureUrl)
                        try FileManager.default.moveItem(at: srcBinaryUrl, to: dstBinaryUrl)
                    } catch {
                        self.logDebug("Error while moving KeySet \(identifier) to final destination: \(error)")
                        // do nothing, just ignore this keySetHolder
                        return
                    }

                    let keySetHolder = ExposureKeySetHolder(identifier: identifier,
                                                            signatureFilename: dstSignatureFilename,
                                                            binaryFilename: dstBinaryFilename,
                                                            processDate: nil,
                                                            creationDate: Date())
                    keySetHolders.append(keySetHolder)
                }

                promise(.success(keySetHolders))
            }
        }
        .eraseToAnyPublisher()
    }

    // stores the downloaded keysets holders and returns the final list of keysets holders on disk
    private func storeDownloadedKeySetsHolders(_ downloadedKeySetsHolders: [ExposureKeySetHolder]) -> AnyPublisher<(), ExposureDataError> {
        return Deferred {
            Future { promise in
                self.storageController.requestExclusiveAccess { storageController in
                    var keySetHolders = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []

                    downloadedKeySetsHolders.forEach { keySetHolder in
                        let matchesKeySetsHolder: (ExposureKeySetHolder) -> Bool = { $0.identifier == keySetHolder.identifier }

                        if !keySetHolders.contains(where: matchesKeySetsHolder) {
                            keySetHolders.append(keySetHolder)
                        }
                    }

                    self.logDebug("Storing final keySets to process: \(keySetHolders.map { $0.identifier }.joined(separator: "\n"))")

                    storageController.store(object: keySetHolders,
                                            identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) { _ in
                        // ignore any storage error - in that case the keyset will be downloaded and processed again
                        promise(.success(()))
                    }
                }
            }
        }
        .share()
        .eraseToAnyPublisher()
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let localPathProvider: LocalPathProviding
    private let exposureKeySetIdentifiers: [String]
}
