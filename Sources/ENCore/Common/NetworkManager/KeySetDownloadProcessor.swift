/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import RxSwift
import ENFoundation
import Foundation

/// @mockable(history:process = true; storeDownloadedKeySetsHolder = true)
protocol KeySetDownloadProcessing {
    func process(identifier: String, url: URL) -> Completable
    func storeDownloadedKeySetsHolder(_ keySetHolder: ExposureKeySetHolder) -> Completable
    func storeIgnoredKeySetsHolders(_ keySetHolders: [ExposureKeySetHolder]) -> Completable
}

final class KeySetDownloadProcessor: KeySetDownloadProcessing, Logging {

    init(storageController: StorageControlling,
         localPathProvider: LocalPathProviding,
         fileManager: FileManaging) {
        self.storageController = storageController
        self.localPathProvider = localPathProvider
        self.fileManager = fileManager
    }

    func process(identifier: String, url: URL) -> Completable {
        createKeySetHolder(forDownloadedKeySet: (identifier, url))
            .flatMapCompletable(storeDownloadedKeySetsHolder)
    }

    private func createKeySetHolder(forDownloadedKeySet keySet: (String, URL)) -> Single<ExposureKeySetHolder> {
        return .create { (observer) -> Disposable in

            guard let keySetStorageUrl = self.localPathProvider.path(for: .exposureKeySets) else {
                observer(.failure(ExposureDataError.internalError))
                return Disposables.create()
            }

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
                observer(.failure(ExposureDataError.internalError))
                return Disposables.create()
            }

            let keySetHolder = ExposureKeySetHolder(identifier: identifier,
                                                    signatureFilename: dstSignatureFilename,
                                                    binaryFilename: dstBinaryFilename,
                                                    processDate: nil,
                                                    creationDate: currentDate())
            observer(.success(keySetHolder))

            return Disposables.create()
        }
    }

    func storeDownloadedKeySetsHolder(_ keySetHolder: ExposureKeySetHolder) -> Completable {
        return .create { (observer) -> Disposable in

            self.storageController.requestExclusiveAccess { storageController in
                var keySetHolders = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []

                let matchesKeySetsHolder: (ExposureKeySetHolder) -> Bool = { $0.identifier == keySetHolder.identifier }

                if !keySetHolders.contains(where: matchesKeySetsHolder) {
                    keySetHolders.append(keySetHolder)
                }

                storageController.store(object: keySetHolders,
                                        identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) { _ in
                    // ignore any storage error - in that case the keyset will be downloaded and processed again
                    observer(.completed)
                }
            }

            return Disposables.create()
        }
    }
    
    /// Stores a batch of keysets holders
    func storeIgnoredKeySetsHolders(_ keySetHolders: [ExposureKeySetHolder]) -> Completable {
        return .create { (observer) -> Disposable in

            self.logDebug("Storing ignored keysetholders")
            
            self.storageController.requestExclusiveAccess { storageController in
                var updatedKeySetHolders = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []
                let existingKeySetHolderIds = updatedKeySetHolders.map { $0.identifier }
                let deduplicatedKeySetHolders = keySetHolders.filter { !existingKeySetHolderIds.contains($0.identifier) }
                
                updatedKeySetHolders.append(contentsOf: deduplicatedKeySetHolders)
                
                storageController.store(object: keySetHolders,
                                        identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) { _ in
                    // ignore any storage error - in that case the keyset will be downloaded and processed again
                    observer(.completed)
                }
            }

            return Disposables.create()
        }
    }

    private let signatureFilename = "export.sig"
    private let binaryFilename = "export.bin"
    private let storageController: StorageControlling
    private let localPathProvider: LocalPathProviding
    private let fileManager: FileManaging
    private let disposeBag = DisposeBag()
}
