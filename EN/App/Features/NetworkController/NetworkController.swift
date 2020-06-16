/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum NetworkControllerError: Error {
    case cantAccessDirectory
}

final class NetworkController: NetworkControlling {
    
     // MARK: - Manifest
    
    func getManifest(completion: @escaping (Result<Manifest, Error>) -> Void) {
        
        // verify is there is a manifest available
        if let manifest = self.storageController.retrieveObject(identifiedBy: Manifest.key, ofType: Manifest.self) {
            completion(.success(manifest))
        } else {
            self.networkManager.getManifest { result in
                switch(result) {
                case let .failure(error):
                    completion(.failure(error))
                    break;
                case let .success(manifest):
                    
                    //LocalStore.shared.manifest = manifest
                    completion(.success(manifest))
                    break;
                }
            }
        }
    }
    
    
    // MARK: - Exposure Key Processing
    func getExposureKeySet(exposureKeySet:String, completion: @escaping (Result<[URL], Error>) -> ()) {
        
        self.networkManager.getDiagnosisKeys(exposureKeySet) { result in
            switch(result) {
            case let .failure(error):
                completion(.failure(error))
                break;
            case let .success(exposureKeySet):
                
                do {
                    let urls = try self.processExposureKeySet(exposureKeySet: exposureKeySet)
                    completion(.success(urls))
                } catch {
                    completion(.failure(error))
                }
                break;
            }
        }
        
    }
    
    private func processExposureKeySet(exposureKeySet:ExposureKeySet) throws -> [URL] {
        // save to disk temporary, the framework expects [URL]
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw NetworkControllerError.cantAccessDirectory
        }
        
        let binaryUrl = cachesDirectory.appendingPathComponent(ExposureKeySet.EXPORT_BINARY)
        let signatureUrl = cachesDirectory.appendingPathComponent(ExposureKeySet.EXPORT_SIGNATURE)
        
        // write to temporary location
        try exposureKeySet.keys.write(to: binaryUrl)
        try exposureKeySet.signature.write(to: signatureUrl)
        
        return [binaryUrl, signatureUrl]
    }
    
    func getResourceBundle() {
        
    }
    
    func getRiskCalculationParameters(appConfig:String) {
        self.networkManager.getRiskCalculationParameters(appConfig: appConfig) { result in
            switch(result) {
            case let .failure(error):
                break;
            case let .success(params):
                // todo save
                break;
            }
        }
    }
    
    func getAppConfig() -> AppConfig {
        return AppConfig(version: 1, manifestFrequency: 1, decoyProbability: 1)
    }
    
    func register() {
        
    }
    
    func postKeys(diagnosisKeys:DiagnosisKeys) {
        self.networkManager.postKeys(diagnosisKeys: diagnosisKeys) { error in
            // handle?
        }
    }
    
    func postStopKeys() {
        
        // generate decoy data
        var keys = [DiagnosisKey]()
        
        // how many days, max 14
        let days = Int.random(in: 1 ... 14)
        for _ in 1...days {
            var bytes = Data(count: 16)
            _ = bytes.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!)
            }
            
            let key = DiagnosisKey(
                keyData: bytes,
                rollingPeriod: 1,
                rollingStartNumber: 2648160,
                transmissionRiskLevel: 0)
            
            keys.append(key)
        }
        
        let diagnosisKeys = DiagnosisKeys(keys: keys, padding: "unknown")
        self.networkManager.postKeys(diagnosisKeys: diagnosisKeys) { error in
            if let error = error {
                // TODO: Handle
            }
            
            // TODO: success?
        }
    }
    
    func serialize() {
        
    }
    
    func deserialize() {
        
    }
    
    
    init(networkManager:NetworkManaging,
         storageController:StorageControlling) {
        self.networkManager = networkManager
        self.storageController = storageController
    }
    
    private let networkManager:NetworkManaging
    private let storageController:StorageControlling
}
