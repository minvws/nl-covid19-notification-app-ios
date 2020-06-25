/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol StoreKey {
    var asString: String { get }
    var storeType: StoreType { get }
}

protocol CodableStoreKey: StoreKey {
    associatedtype Object: Codable

    var objectType: Object.Type { get }
}

struct StorageKey: StoreKey {
    var asString: String { name }
    let storeType: StoreType

    init(name: String, storeType: StoreType) {
        self.name = name
        self.storeType = storeType
    }

    private let name: String
}

struct CodableStorageKey<Object: Codable>: CodableStoreKey {
    var asString: String { name }
    var objectType: Object.Type { return Object.self }

    let storeType: StoreType

    init(name: String, storeType: StoreType) {
        self.name = name
        self.storeType = storeType
    }

    private let name: String
}

enum StoreType {
    case secure
    case insecure(volatile: Bool, maximumAge: TimeInterval? = nil)
}

enum StoreError: Error {
    case keychainError
    case fileSystemError
    case cannotEncode
}

/// @mockable
protocol StorageControlling {
    func store<Key: StoreKey>(data: Data, identifiedBy key: Key, completion: @escaping (StoreError?) -> ())
    func retrieveData<Key: StoreKey>(identifiedBy key: Key) -> Data?
    func removeData<Key: StoreKey>(for key: Key, completion: @escaping (StoreError?) -> ())

    func requestExclusiveAccess(_ work: @escaping (StorageControlling) -> ())
}

/// @mockable
protocol StorageControllerBuildable {
    /// Builds StorageController
    ///
    /// - Parameter listener: Listener of created StorageController
    func build() -> StorageControlling
}

private final class StorageDependencyProvider: DependencyProvider<EmptyDependency> {
    var localPathProvider: LocalPathProviding {
        return LocalPathProvider()
    }
}

final class StorageControllerBuilder: Builder<EmptyDependency>, StorageControllerBuildable {
    func build() -> StorageControlling {
        let dependencyProvider = StorageDependencyProvider()

        return StorageController(localPathProvider: dependencyProvider.localPathProvider)
    }
}
