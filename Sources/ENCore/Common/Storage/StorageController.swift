/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension StorageControlling {
    func store<Object: Encodable, Key: StoreKey>(object: Object, identifiedBy key: Key, completion: @escaping (StoreError?) -> ()) {
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

    func store<Key>(data: Data, identifiedBy key: Key, completion: @escaping (StoreError?) -> ()) where Key: StoreKey {
        return store(guardAccess: true, data: data, identifiedBy: key, completion: completion)
    }

    func retrieveData<Key>(identifiedBy key: Key) -> Data? where Key: StoreKey {
        return retrieveData(guardAccess: true, identifiedBy: key)
    }

    func removeData<Key: StoreKey>(for key: Key, completion: @escaping (StoreError?) -> ()) {
        return removeData(guardAccess: true, identifiedBy: key, completion: completion)
    }

    func requestExclusiveAccess(_ work: @escaping (StorageControlling) -> ()) {
        accessQueue.async(flags: .barrier) {
            work(ExclusiveStorageController(storageController: self))
        }
    }

    // MARK: - Private

    fileprivate func store<Key>(guardAccess: Bool, data: Data, identifiedBy key: Key, completion: @escaping (StoreError?) -> ()) where Key: StoreKey {
        let operation: () -> () = {
            guard self.storeAvailable else {
                self.inMemoryStore[key.asString] = data

                DispatchQueue.main.async {
                    completion(nil)
                }

                return
            }

            switch key.storeType {
            case .secure:
                self.secureAccessQueue.async {
                    let success = self.storeSecure(data: data, with: key.asString)

                    DispatchQueue.main.async {
                        completion(success ? nil : .keychainError)
                    }
                }
            case let .insecure(volatile: isVolatile, _):
                guard let storeUrl = self.storeUrl(isVolatile: isVolatile) else {
                    self.inMemoryStore[key.asString] = data

                    completion(nil)
                    return
                }

                self.storageAccessQueue.async {
                    let success = self.store(data: data, for: key.asString, storeUrl: storeUrl)

                    DispatchQueue.main.async {
                        completion(success ? nil : .fileSystemError)
                    }
                }
            }
        }

        // execute storage operation
        guardAccess ? accessQueue.sync(execute: operation) : operation()
    }

    fileprivate func retrieveData<Key>(guardAccess: Bool, identifiedBy key: Key) -> Data? where Key: StoreKey {
        var data: Data?

        let operation = {
            guard self.storeAvailable else {
                data = self.inMemoryStore[key.asString] as? Data
                return
            }

            switch key.storeType {
            case .secure:

                self.secureAccessQueue.sync {
                    data = self.retrieveDataSecure(for: key.asString)
                }

            case let .insecure(volatile: isVolatile, maximumAge: maximumAge):
                guard let storeUrl = self.storeUrl(isVolatile: isVolatile) else {
                    data = self.inMemoryStore[key.asString] as? Data
                    return
                }

                self.storageAccessQueue.sync {
                    data = self.retrieveData(for: key.asString, storeUrl: storeUrl, maximumAge: maximumAge)
                }
            }
        }

        guardAccess ? accessQueue.sync(execute: operation) : operation()

        return data
    }

    func removeData<Key: StoreKey>(guardAccess: Bool, identifiedBy key: Key, completion: @escaping (StoreError?) -> ()) {
        let operation = {
            guard self.retrieveData(identifiedBy: key) != nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }

                return
            }

            var result: StoreError?

            switch key.storeType {
            case .secure:
                self.secureAccessQueue.sync {
                    result = self.removeSecure(for: key.asString) ? nil : .keychainError
                }
            case let .insecure(isVolatile, _):
                guard let storeUrl = self.storeUrl(isVolatile: isVolatile) else {
                    self.inMemoryStore[key.asString] = nil
                    return
                }

                self.storageAccessQueue.sync {
                    result = self.removeData(for: key.asString, storeUrl: storeUrl) ? nil : .fileSystemError
                }
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }

        guardAccess ? accessQueue.sync(execute: operation) : operation()
    }

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

    private func retrieveData(for key: String, storeUrl: URL, maximumAge: TimeInterval?) -> Data? {
        let url = storeUrl.appendingPathComponent(key)

        // check date last modified, if any
        if let maximumAge = maximumAge,
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
            let dateLastModified = attributes[.modificationDate] as? Date {

            if dateLastModified.addingTimeInterval(maximumAge) < Date() {
                return nil
            }
        }

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

    private func removeData(for key: String, storeUrl: URL) -> Bool {
        let url = storeUrl.appendingPathComponent(key)

        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Secure

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

    private func removeSecure(for key: String) -> Bool {
        let query = keychainQuery(for: key)

        let resultCode = SecItemDelete(query as CFDictionary)
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
    private let accessQueue = DispatchQueue(label: "accessQueue", attributes: .concurrent)

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

private final class ExclusiveStorageController: StorageControlling {

    fileprivate init(storageController: StorageController) {
        self.storageController = storageController
    }

    func store<Key>(data: Data, identifiedBy key: Key, completion: @escaping (StoreError?) -> ()) where Key: StoreKey {
        storageController.store(guardAccess: false, data: data, identifiedBy: key, completion: completion)
    }

    func retrieveData<Key>(identifiedBy key: Key) -> Data? where Key: StoreKey {
        storageController.retrieveData(guardAccess: false, identifiedBy: key)
    }

    func removeData<Key>(for key: Key, completion: @escaping (StoreError?) -> ()) where Key: StoreKey {
        storageController.removeData(for: key, completion: completion)
    }

    func requestExclusiveAccess(_ work: (StorageControlling) -> ()) {
        // already has exclusive access
        work(self)
    }

    // MARK: - Private

    private let storageController: StorageController
}
