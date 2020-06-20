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

struct AnyStoreKey: StoreKey {
    var asString: String { name }
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

    func requestExclusiveAccess(_ work: @escaping (StorageControlling) -> ())
}

/// @mockable
protocol StorageControllerBuildable {
    /// Builds StorageController
    ///
    /// - Parameter listener: Listener of created StorageController
    func build() -> StorageControlling
}

final class StorageControllerBuilder: Builder<EmptyDependency>, StorageControllerBuildable {
    func build() -> StorageControlling {
        return StorageController()
    }
}
