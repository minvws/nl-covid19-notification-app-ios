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

enum StoreType {
    case secure
    case insecure(volatile: Bool)
}

enum StoreError: Error {
    case keychainError
    case fileSystemError
    case cannotEncode
}

/// @mockable
protocol StorageControlling {
    func store<Key: StoreKey>(data: Data, identifiedBy key: Key, completion: @escaping (Error?) -> ())
    func retrieveData<Key: StoreKey>(identifiedBy key: Key) -> Data?
}

extension StorageControlling {
    func store<Object: Codable, Key: StoreKey>(object: Object, identifiedBy key: Key, completion: @escaping (Error?) -> ()) {
        guard let data = try? JSONEncoder().encode(object) else {
            completion(StoreError.cannotEncode)
            return
        }

        store(data: data, identifiedBy: key, completion: completion)
    }

    func retrieveObject<Object: Decodable, Key: StoreKey>(identifiedBy key: Key, ofType type: Object.Type) -> Object? {
        guard let data = retrieveData(identifiedBy: key) else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)
    }
}

final class StorageController: StorageControlling {

    init() {
        prepareStore()
    }

    // MARK: - StorageControlling

    func store<Key>(data: Data, identifiedBy key: Key, completion: @escaping (Error?) -> ()) where Key: StoreKey {
        guard storeAvailable else {
            inMemoryStore[key.asString] = data

            completion(nil)

            return
        }

        switch key.storeType {
        case .secure:
            secureAccessQueue.async {
                let success = self.storeSecure(data: data, with: key.asString)

                DispatchQueue.main.async {
                    completion(success ? nil : StoreError.keychainError)
                }
            }
        case let .insecure(volatile: isVolatile):
            guard let storeUrl = self.storeUrl(isVolatile: isVolatile) else {
                inMemoryStore[key.asString] = data

                completion(nil)
                return
            }

            storageAccessQueue.async {
                let success = self.store(data: data, for: key.asString, storeUrl: storeUrl)

                DispatchQueue.main.async {
                    completion(success ? nil : StoreError.fileSystemError)
                }
            }
        }
    }

    func retrieveData<Key>(identifiedBy key: Key) -> Data? where Key: StoreKey {
        guard storeAvailable else {
            return inMemoryStore[key.asString] as? Data
        }

        switch key.storeType {
        case .secure:

            var data: Data?

            secureAccessQueue.sync {
                data = self.retrieveDataSecure(for: key.asString)
            }

            return data
        case let .insecure(volatile: isVolatile):
            guard let storeUrl = self.storeUrl(isVolatile: isVolatile) else {
                return inMemoryStore[key.asString] as? Data
            }

            var data: Data?

            storageAccessQueue.sync {
                data = self.retrieveData(for: key.asString, storeUrl: storeUrl)
            }

            return data
        }
    }

    // MARK: - Private

    private func prepareStore() {
        guard let storeUrl = self.storeUrl(isVolatile: false) else {
            return
        }

        guard let volatileStoreUrl = self.storeUrl(isVolatile: true) else {
            return
        }

        do {
            try FileManager.default.createDirectory(at: storeUrl,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)

            try FileManager.default.createDirectory(at: volatileStoreUrl,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            return
        }

        storeAvailable = true
    }

    private func retrieveData(for key: String, storeUrl: URL) -> Data? {
        let url = storeUrl.appendingPathComponent(key)

        return try? Data(contentsOf: url)
    }

    private func store(data: Data, for key: String, storeUrl: URL) -> Bool {
        let url = storeUrl.appendingPathComponent(key)

        do {
            try data.write(to: url, options: .atomicWrite)
        } catch {
            return false
        }

        return true
    }

    private func retrieveDataSecure(for key: String) -> Data? {
        var query = keychainQuery(for: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue

        var result: AnyObject?
        let resultCode = SecItemCopyMatching(query as CFDictionary, &result)

        if resultCode == errSecSuccess,
            let resultItems = result as? [String: AnyObject],
            let data = resultItems[kSecValueData as String] as? Data {
            return data
        }

        return nil
    }

    private func storeSecure(data: Data, with key: String) -> Bool {
        guard retrieveDataSecure(for: key) == nil else {
            // update instead of store
            let query = keychainQuery(for: key)

            var update = [String: AnyObject]()
            update[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            update[kSecValueData as String] = data as AnyObject

            let resultCode = SecItemUpdate(query as CFDictionary, update as CFDictionary)
            return resultCode == errSecSuccess
        }

        // store
        var query = keychainQuery(for: key)
        query[kSecValueData as String] = data as AnyObject
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let resultCode = SecItemAdd(query as CFDictionary, nil)
        return resultCode == errSecSuccess
    }

    private func keychainQuery(for key: String) -> [String: AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrAccount as String] = key as AnyObject
        query[kSecAttrService as String] = serviceName as AnyObject

        return query
    }

    private let serviceName = (Bundle.main.bundleIdentifier ?? "nl.rijksoverheid.en") + ".exposure"
    private var storeAvailable = false
    private var inMemoryStore: [String: Any] = [:]
    private let secureAccessQueue = DispatchQueue(label: "secureAccessQueue")
    private let storageAccessQueue = DispatchQueue(label: "storageAccessQueue")

    private func storeUrl(isVolatile: Bool) -> URL? {
        let base = isVolatile ? cacheUrl : documentsUrl

        return base?.appendingPathComponent("store")
    }

    private var cacheUrl: URL? {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)

        return urls.first
    }

    private var documentsUrl: URL? {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        return urls.first
    }
}
