/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

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

/// @mockable
protocol RequestExposureKeySetsDataOperationProtocol {
    func execute() -> Completable
}

final class RequestExposureKeySetsDataOperation: RequestExposureKeySetsDataOperationProtocol, Logging {
    private let signatureFilename = "export.sig"
    private let binaryFilename = "export.bin"

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         exposureKeySetIdentifiers: [String],
         featureFlagController: FeatureFlagControlling,
         keySetDownloadProcessor: KeySetDownloadProcessing) {
        self.networkController = networkController
        self.storageController = storageController
        self.exposureKeySetIdentifiers = exposureKeySetIdentifiers
        self.featureFlagController = featureFlagController
        self.keySetDownloadProcessor = keySetDownloadProcessor
    }

    // MARK: - ExposureDataOperation

    func execute() -> Completable {
        logDebug("--- START REQUESTING KEYSETS ---")

        let storedKeySetsHolders = getStoredKeySetsHolders()

        logDebug("KeySet: Total KeySetIdentifiers: \(exposureKeySetIdentifiers.count)")

        let identifiers = removeAlreadyDownloadedOrProcessedKeySetIdentifiers(from: exposureKeySetIdentifiers,
                                                                              storedKeySetsHolders: storedKeySetsHolders)

        logDebug("KeySet: KeySetIdentifiers after removing already downloaded or processed identifiers: \(identifiers)")

        guard identifiers.count > 0 else {
            logDebug("No additional key sets to download")
            logDebug("--- END REQUESTING KEYSETS ---")

            return .empty()
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

        if featureFlagController.isFeatureFlagEnabled(feature: .backgroundKeysetDownloading) {
            
            networkController.fetchExposureKeySetsInBackground(identifiers: identifiers)
                        
            logDebug("Triggered background download for keysets with identifiers: \(identifiers.joined(separator: "\n"))")
            logDebug("--- END REQUESTING KEYSETS ---")
            
            return .empty()
        }
        
        logDebug("KeySet: Requesting \(identifiers.count) Exposure KeySets: \(identifiers.joined(separator: "\n"))")
        
        // download remaining keysets
        let exposureKeySetStreams: [Single<(String, URL)>] = identifiers.map { identifier in
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
                self.keySetDownloadProcessor.process(identifier: identifierUrlCombo.0, url: identifierUrlCombo.1)
            }
            .toArray() // toArray is called only after the creation and storage of keysetholders. This means that if at any point during this process the app is killed due to high CPU usage, the previous progress will not be lost and the app will only have to download the remaining keysets
            .do { [weak self] _ in
                let diff = CFAbsoluteTimeGetCurrent() - start
                self?.logDebug("KeySet: Requesting Keysets Took \(diff) seconds")
                self?.logDebug("KeySet: Requesting KeySets Completed")

            } onError: { [weak self] _ in
                self?.logDebug("KeySet: Requesting KeySets Failed")
            }
            .asCompletable()
    }

    // MARK: - Private

    private func ignoreFirstKeySetBatch(keySetIdentifiers: [String]) -> Completable {
        logDebug("KeySet: Ignoring KeySets because it is the first batch after first install: \(keySetIdentifiers.joined(separator: "\n"))")

        return Observable.from(keySetIdentifiers)
            .flatMap { identifier in
                self.createIgnoredKeySetHolder(forKeySetIdentifier: identifier)
            }
            .flatMap { keySetHolder in
                self.keySetDownloadProcessor.storeDownloadedKeySetsHolder(keySetHolder)
            }
            .do(onError: { _ in
                self.logDebug("KeySet: Creating ignored keysets failed ")
            }, onCompleted: {
                self.storageController.store(object: true, identifiedBy: ExposureDataStorageKey.initialKeySetsIgnored, completion: { _ in })
            })
            .asCompletable()
    }

    private func getStoredKeySetsHolders() -> [ExposureKeySetHolder] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []
    }

    private func removeAlreadyDownloadedOrProcessedKeySetIdentifiers(from identifiers: [String],
                                                                     storedKeySetsHolders: [ExposureKeySetHolder]) -> [String] {
        let isNotDownloadedOrProcessed: (String) -> Bool = { identifier in !storedKeySetsHolders.contains { $0.identifier == identifier } }
        return identifiers.filter(isNotDownloadedOrProcessed)
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

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let exposureKeySetIdentifiers: [String]
    private let featureFlagController: FeatureFlagControlling
    private let keySetDownloadProcessor: KeySetDownloadProcessing
}
