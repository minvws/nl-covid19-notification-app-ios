/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import CryptoKit
import Foundation

protocol StoreKey {
    var asString: String { get }
    var isSecure: Bool { get }
}

enum StoreError: Error {
    case unknown
}

/// @mockable
protocol StorageControlling {
    func store<Key: StoreKey>(data: Data, identifiedBy key: Key, completion: @escaping (Error?) -> ())
    func retrieveData<Key: StoreKey>(identifiedBy key: Key, completion: @escaping (Result<Data, StoreError>) -> ())
}

final class StorageController: StorageControlling {
    // MARK: - StorageControlling
    
    func store<Key>(data: Data, identifiedBy key: Key, completion: (Error?) -> ()) where Key : StoreKey {
        UserDefaults.standard.set(data, forKey: key.asString)
                
        completion(nil)
    }
    
    func retrieveData<Key>(identifiedBy key: Key, completion: @escaping (Result<Data, StoreError>) -> ()) where Key : StoreKey {
        if let data = UserDefaults.standard.data(forKey: key.asString) {
            completion(.success(data))
        } else {
            completion(.failure(.unknown))
        }
    }
}
