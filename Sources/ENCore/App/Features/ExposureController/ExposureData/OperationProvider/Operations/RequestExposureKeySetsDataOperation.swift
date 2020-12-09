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
    let signatureFilename: String?
    let binaryFilename: String?
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

        logDebug("KeySet: Total KeySetIdentifiers: \(exposureKeySetIdentifiers.count)")

        let identifiers = removeAlreadyDownloadedOrProcessedKeySetIdentifiers(from: exposureKeySetIdentifiers,
                                                                              storedKeySetsHolders: storedKeySetsHolders)

        logDebug("KeySet: KeySetIdentifiers after removing already downloaded or processed identifiers: \(identifiers)")

        guard identifiers.count > 0 else {
            logDebug("No additional key sets to download")
            logDebug("--- END REQUESTING KEYSETS ---")

            return Just(())
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        // The first time we retrieve keysets, we ignore the entire batch because:
        // - We are not that interested in previous key files if the app didn't have the app yet
        // - We want to prevent app crashes when we are downloading too many keyfiles in the background
        var ignoredInitialKeySets = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.initialKeySetsIgnored) ?? false

        // If we have keysets, we already ignored the initial set (the user probably updated from an earlier version without this logic)
        if !storedKeySetsHolders.isEmpty, !ignoredInitialKeySets {
            storageController.store(object: true, identifiedBy: ExposureDataStorageKey.initialKeySetsIgnored, completion: { _ in })
            ignoredInitialKeySets = true
        }

        if !ignoredInitialKeySets {
            return ignoreFirstKeySetBatch(keySetIdentifiers: identifiers)
        }

        logDebug("KeySet: Requesting \(identifiers.count) Exposure KeySets: \(identifiers.joined(separator: "\n"))")

        // download remaining keysets
        let exposureKeySetStreams: [AnyPublisher<(String, URL), NetworkError>] = identifiers.map { identifier in
            self.networkController
                .fetchExposureKeySet(identifier: identifier)
                .eraseToAnyPublisher()
        }

        let start = CFAbsoluteTimeGetCurrent()

        // Optionally limit the number of concurrent requests we are doing. This might help to not overload the network connection or the CPU
        let maximumConcurrentFetches = exposureKeySetStreams.count

        return Publishers.Sequence<[AnyPublisher<(String, URL), NetworkError>], NetworkError>(sequence: exposureKeySetStreams)
            .flatMap(maxPublishers: .max(maximumConcurrentFetches)) { $0 }
            .mapError { error in
                self.logError("KeySet: RequestExposureKeySetsDataOperation Error: \(error)")
                return error.asExposureDataError
            }
            .flatMap { identifierUrlCombo in
                self.createKeySetHolders(forDownloadedKeySets: [identifierUrlCombo])
            }
            .flatMap { keySetHolders in
                self.storeDownloadedKeySetsHolders(keySetHolders)
            }
            .collect() // Collect is called only after the creation and storage of keysetholders. This means that if at any point during this process the app is killed due to high CPU usage, the previous progress will not be lost and the app will only have to download the remaining keysets
            .handleEvents(
                receiveCompletion: { completion in

                    let diff = CFAbsoluteTimeGetCurrent() - start
                    self.logDebug("KeySet: Requesting Keysets Took \(diff) seconds")

                    switch completion {
                    case .finished:
                        self.logDebug("KeySet: Requesting KeySets Completed")
                    case .failure:
                        self.logDebug("KeySet: Requesting KeySets Failed")
                    }

                    self.logDebug("--- END REQUESTING KEYSETS ---")
                },
                receiveCancel: { self.logDebug("--- REQUESTING KEYSETS CANCELLED ---") }
            )
            .compactMap { _ in () }
            .share()
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func ignoreFirstKeySetBatch(keySetIdentifiers: [String]) -> AnyPublisher<(), ExposureDataError> {
        logDebug("KeySet: Ignoring KeySets because it is the first batch after first install: \(keySetIdentifiers.joined(separator: "\n"))")

        return createIgnoredKeySetHolders(forKeySetIdentifiers: keySetIdentifiers)
            .flatMap { keySetHolders in
                self.storeDownloadedKeySetsHolders(keySetHolders)
            }
            .handleEvents(
                receiveCompletion: { completion in

                    switch completion {
                    case .finished:
                        self.storageController.store(object: true, identifiedBy: ExposureDataStorageKey.initialKeySetsIgnored, completion: { _ in })
                    case .failure:
                        self.logDebug("KeySet: Creating ignored keysets failed ")
                    }
                },
                receiveCancel: {}
            )
            .eraseToAnyPublisher()
    }

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
                    let start = CFAbsoluteTimeGetCurrent()

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

                    let diff = CFAbsoluteTimeGetCurrent() - start
                    self.logDebug("Creating KeySetHolder Took \(diff) seconds")
                }

                promise(.success(keySetHolders))
            }
        }
        .eraseToAnyPublisher()
    }

    private func createIgnoredKeySetHolders(forKeySetIdentifiers identifiers: [String]) -> AnyPublisher<[ExposureKeySetHolder], ExposureDataError> {
        return Deferred {
            return Future<[ExposureKeySetHolder], ExposureDataError> { promise in

                // mark all keysets as processed
                // ensure processDate is in the past to not have these keysets count towards the rate limit
                let keySetHolders = identifiers.map { identifier in
                    ExposureKeySetHolder(identifier: identifier,
                                         signatureFilename: nil,
                                         binaryFilename: nil,
                                         processDate: Date().addingTimeInterval(-60 * 60 * 24),
                                         creationDate: Date())
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
                let start = CFAbsoluteTimeGetCurrent()

                self.storageController.requestExclusiveAccess { storageController in
                    var keySetHolders = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []

                    downloadedKeySetsHolders.forEach { keySetHolder in
                        let matchesKeySetsHolder: (ExposureKeySetHolder) -> Bool = { $0.identifier == keySetHolder.identifier }

                        if !keySetHolders.contains(where: matchesKeySetsHolder) {
                            self.logDebug("Adding \(keySetHolder.identifier) to stored keysetholders")
                            keySetHolders.append(keySetHolder)
                        }
                    }

                    storageController.store(object: keySetHolders,
                                            identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) { _ in

                        let diff = CFAbsoluteTimeGetCurrent() - start
                        self.logDebug("Storing KeySetHolders Took \(diff) seconds")

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

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
