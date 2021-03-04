/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// On iOS version lower than 13, encoding values such as Booleans is not supported. To work around this we wrap the value in a struct
private struct StorageWrapper<T>: Codable where T: Codable {
    let wrapped: T
}

extension StorageControlling {
    func store<Key: CodableStoreKey>(object: Key.Object, identifiedBy key: Key, completion: @escaping (StoreError?) -> ()) {

        var encodedData = try? JSONEncoder().encode(object)

        // fallback in case encoding didn't work, wrap the object
        if encodedData == nil {
            let wrapper = StorageWrapper(wrapped: object)
            encodedData = try? JSONEncoder().encode(wrapper)
        }

        guard let dataToStore = encodedData else {
            completion(StoreError.cannotEncode)
            return
        }

        store(data: dataToStore, identifiedBy: key, completion: completion)
    }

    func retrieveObject<Key: CodableStoreKey>(identifiedBy key: Key) -> Key.Object? {
        guard let data = retrieveData(identifiedBy: key) else {
            return nil
        }

        var objectToReturn = try? JSONDecoder().decode(key.objectType, from: data)

        // fallback, maybe the object was stored in a wrapper
        if objectToReturn == nil {
            let wrappedValue = try? JSONDecoder().decode(StorageWrapper<Key.Object>.self, from: data)
            objectToReturn = wrappedValue?.wrapped
        }

        if objectToReturn == nil {
            // data is corrupt / backwards incompatible - delete it
            removeData(for: key, completion: { _ in })
        }

        return objectToReturn
    }
}

final class StorageController: StorageControlling, Logging {

    init(fileManager: FileManaging, localPathProvider: LocalPathProviding, environmentController: EnvironmentControlling) {
        self.fileManager = fileManager
        self.localPathProvider = localPathProvider
        self.environmentController = environmentController
    }

    // MARK: - StorageControlling

    func prepareStore() {

        guard !storeAvailable else {
            return
        }

        guard let storeUrl = self.storeUrl(isVolatile: false) else {
            return
        }

        guard let volatileStoreUrl = self.storeUrl(isVolatile: true) else {
            return
        }

        do {
            try fileManager.createDirectory(at: storeUrl,
                                            withIntermediateDirectories: true,
                                            attributes: nil)

            try fileManager.createDirectory(at: volatileStoreUrl,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        } catch {
            logDebug("Error preparing store: \(error)")
            return
        }

        clearTemporaryDirectory()

        storeAvailable = true
    }

    fileprivate func clearTemporaryDirectory() {

        let tempFolderURL = localPathProvider.temporaryDirectoryUrl

        logDebug("Removing contents of temporary folder: \(tempFolderURL)")

        do {
            try fileManager.removeItem(at: tempFolderURL)
        } catch {
            logError("Error deleting file at url \(tempFolderURL) with error: \(error)")
        }
    }

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

    private func retrieveData(for key: String, storeUrl: URL, maximumAge: TimeInterval?) -> Data? {
        let url = storeUrl.appendingPathComponent(key)

        // check date last modified, if any
        if let maximumAge = maximumAge,
            let attributes = try? fileManager.attributesOfItem(atPath: url.path),
            let dateLastModified = attributes[.modificationDate] as? Date {

            if dateLastModified.addingTimeInterval(maximumAge) < Date() {
                return nil
            }
        }

        // check if path exists and is a file
        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            return nil
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
            try fileManager.removeItem(at: url)
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

    private let fileManager: FileManaging
    private let localPathProvider: LocalPathProviding
    private let environmentController: EnvironmentControlling
    private let serviceName = (Bundle.main.bundleIdentifier ?? "nl.rijksoverheid.en") + ".exposure"
    private var inMemoryStore: [String: Any] = [:]
    private let secureAccessQueue = DispatchQueue(label: "secureAccessQueue")
    private let storageAccessQueue = DispatchQueue(label: "storageAccessQueue")
    private let accessQueue = DispatchQueue(label: "accessQueue", attributes: .concurrent)

    fileprivate func storeUrl(isVolatile: Bool) -> URL? {
        let base = isVolatile ? localPathProvider.path(for: .cache) : localPathProvider.path(for: .documents)

        return base?.appendingPathComponent("store")
    }

    private(set) var storeAvailable = false
}

private final class ExclusiveStorageController: StorageControlling {

    fileprivate init(storageController: StorageController) {
        self.storageController = storageController
    }

    func prepareStore() {
        storageController.prepareStore()
    }

    func storeUrl(isVolatile: Bool) -> URL? {
        return storageController.storeUrl(isVolatile: isVolatile)
    }

    func clearPreviouslyStoredVolatileFiles() {
        storageController.clearTemporaryDirectory()
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
