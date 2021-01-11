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

struct ExposureKeySetHolder: Codable {
    let identifier: String
    let signatureFilename: String?
    let binaryFilename: String?
    let processDate: Date?
    let creationDate: Date

    var processed: Bool { processDate != nil }
}

protocol RequestExposureKeySetsDataOperationProtocol {
    func execute() -> Observable<()>
}

final class RequestExposureKeySetsDataOperation: RequestExposureKeySetsDataOperationProtocol, Logging {
    private let signatureFilename = "export.sig"
    private let binaryFilename = "export.bin"

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         localPathProvider: LocalPathProviding,
         exposureKeySetIdentifiers: [String],
         fileManager: FileManaging) {
        self.networkController = networkController
        self.storageController = storageController
        self.localPathProvider = localPathProvider
        self.exposureKeySetIdentifiers = exposureKeySetIdentifiers
        self.fileManager = fileManager
    }

    // MARK: - ExposureDataOperation

    func execute() -> Observable<()> {
        logDebug("--- START REQUESTING KEYSETS ---")

        let storedKeySetsHolders = getStoredKeySetsHolders()

        logDebug("KeySet: Total KeySetIdentifiers: \(exposureKeySetIdentifiers.count)")

        let identifiers = removeAlreadyDownloadedOrProcessedKeySetIdentifiers(from: exposureKeySetIdentifiers,
                                                                              storedKeySetsHolders: storedKeySetsHolders)

        logDebug("KeySet: KeySetIdentifiers after removing already downloaded or processed identifiers: \(identifiers)")

        guard identifiers.count > 0 else {
            logDebug("No additional key sets to download")
            logDebug("--- END REQUESTING KEYSETS ---")

            return .just(())
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
        let exposureKeySetStreams: [Observable<(String, URL)>] = identifiers.map { identifier in
            self.networkController
                .fetchExposureKeySet(identifier: identifier)
        }

        let start = CFAbsoluteTimeGetCurrent()

        return Observable.from(exposureKeySetStreams)
            .flatMap { $0 }
            .catch { error in
                throw (error as? NetworkError)?.asExposureDataError ?? ExposureDataError.internalError
            }
            .flatMap { identifierUrlCombo in
                self.createKeySetHolder(forDownloadedKeySet: identifierUrlCombo)
            }
            .flatMap { keySetHolder in
                self.storeDownloadedKeySetsHolder(keySetHolder)
            }
            .toArray() // toArray is called only after the creation and storage of keysetholders. This means that if at any point during this process the app is killed due to high CPU usage, the previous progress will not be lost and the app will only have to download the remaining keysets
            .do { [weak self] _ in
                let diff = CFAbsoluteTimeGetCurrent() - start
                self?.logDebug("KeySet: Requesting Keysets Took \(diff) seconds")
                self?.logDebug("KeySet: Requesting KeySets Completed")

            } onError: { [weak self] _ in
                self?.logDebug("KeySet: Requesting KeySets Failed")
            }
            .compactMap { _ in () }
            .asObservable()
            .share()
    }

    // MARK: - Private

    private func ignoreFirstKeySetBatch(keySetIdentifiers: [String]) -> Observable<()> {
        logDebug("KeySet: Ignoring KeySets because it is the first batch after first install: \(keySetIdentifiers.joined(separator: "\n"))")

        return Observable.from(keySetIdentifiers)
            .flatMap { identifier in
                self.createIgnoredKeySetHolder(forKeySetIdentifier: identifier)
            }
            .flatMap { keySetHolder in
                self.storeDownloadedKeySetsHolder(keySetHolder)
            }
            .do(onError: { _ in
                self.logDebug("KeySet: Creating ignored keysets failed ")
            }, onCompleted: {
                self.storageController.store(object: true, identifiedBy: ExposureDataStorageKey.initialKeySetsIgnored, completion: { _ in })
            })
            .compactMap { _ in () }
    }

    private func getStoredKeySetsHolders() -> [ExposureKeySetHolder] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []
    }

    private func removeAlreadyDownloadedOrProcessedKeySetIdentifiers(from identifiers: [String],
                                                                     storedKeySetsHolders: [ExposureKeySetHolder]) -> [String] {
        let isNotDownloadedOrProcessed: (String) -> Bool = { identifier in !storedKeySetsHolders.contains { $0.identifier == identifier } }
        return identifiers.filter(isNotDownloadedOrProcessed)
    }

    private func createKeySetHolder(forDownloadedKeySet keySet: (String, URL)) -> Observable<ExposureKeySetHolder> {
        return .create { (observer) -> Disposable in

            guard let keySetStorageUrl = self.localPathProvider.path(for: .exposureKeySets) else {
                observer.onError(ExposureDataError.internalError)
                return Disposables.create()
            }

            let start = CFAbsoluteTimeGetCurrent()

            let (identifier, localUrl) = keySet
            let srcSignatureUrl = localUrl.appendingPathComponent(self.signatureFilename)
            let srcBinaryUrl = localUrl.appendingPathComponent(self.binaryFilename)

            let dstSignatureFilename = [identifier, "sig"].joined(separator: ".")
            let dstSignatureUrl = keySetStorageUrl.appendingPathComponent(dstSignatureFilename)
            let dstBinaryFilename = [identifier, "bin"].joined(separator: ".")
            let dstBinaryUrl = keySetStorageUrl.appendingPathComponent(dstBinaryFilename)

            do {
                if self.fileManager.fileExists(atPath: dstSignatureUrl.path) {
                    try self.fileManager.removeItem(atPath: dstSignatureUrl.path)
                }

                if self.fileManager.fileExists(atPath: dstBinaryUrl.path) {
                    try self.fileManager.removeItem(atPath: dstBinaryUrl.path)
                }

                try self.fileManager.moveItem(at: srcSignatureUrl, to: dstSignatureUrl)
                try self.fileManager.moveItem(at: srcBinaryUrl, to: dstBinaryUrl)
            } catch {
                self.logDebug("Error while moving KeySet \(identifier) to final destination: \(error)")
                // do nothing, just ignore this keySetHolder
                observer.onError(ExposureDataError.internalError)
                return Disposables.create()
            }

            let keySetHolder = ExposureKeySetHolder(identifier: identifier,
                                                    signatureFilename: dstSignatureFilename,
                                                    binaryFilename: dstBinaryFilename,
                                                    processDate: nil,
                                                    creationDate: Date())

            let diff = CFAbsoluteTimeGetCurrent() - start
            self.logDebug("Creating KeySetHolder Took \(diff) seconds")

            observer.onNext(keySetHolder)
            observer.onCompleted()

            return Disposables.create()
        }
    }

    private func createIgnoredKeySetHolder(forKeySetIdentifier identifier: String) -> Single<ExposureKeySetHolder> {

        // mark keyset as processed
        // ensure processDate is in the past to not have these keysets count towards the rate limit
        return .just(ExposureKeySetHolder(identifier: identifier,
                                          signatureFilename: nil,
                                          binaryFilename: nil,
                                          processDate: Date().addingTimeInterval(-60 * 60 * 24),
                                          creationDate: Date()))
    }

    // stores the downloaded keysets holder
    private func storeDownloadedKeySetsHolder(_ keySetHolder: ExposureKeySetHolder) -> Completable {
        return .create { (observer) -> Disposable in

            let start = CFAbsoluteTimeGetCurrent()

            self.storageController.requestExclusiveAccess { storageController in
                var keySetHolders = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []

                let matchesKeySetsHolder: (ExposureKeySetHolder) -> Bool = { $0.identifier == keySetHolder.identifier }

                if !keySetHolders.contains(where: matchesKeySetsHolder) {
                    self.logDebug("Adding \(keySetHolder.identifier) to stored keysetholders")
                    keySetHolders.append(keySetHolder)
                }

                storageController.store(object: keySetHolders,
                                        identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) { _ in

                    let diff = CFAbsoluteTimeGetCurrent() - start
                    self.logDebug("Storing KeySetHolder Took \(diff) seconds")

                    // ignore any storage error - in that case the keyset will be downloaded and processed again
                    observer(.completed)
                }
            }

            return Disposables.create()
        }
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let localPathProvider: LocalPathProviding
    private let exposureKeySetIdentifiers: [String]
    private let fileManager: FileManaging
}
