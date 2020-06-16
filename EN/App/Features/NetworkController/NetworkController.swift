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
        if let manifest = LocalStore.shared.manifest {
            completion(.success(manifest))
        } else {
            self.networkManager.getManifest { result in
                switch(result) {
                case let .failure(error):
                    completion(.failure(error))
                    break;
                case let .success(manifest):
                    LocalStore.shared.manifest = manifest
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
    
    func getRiskCalculationParameters(appConfig:String) -> RiskCalculationParameters {
        self.networkManager.getRiskCalculationParameters(appConfig: appConfig, completion: <#T##(Error?) -> Void#>)
    }
    
    func getAppConfig() -> AppConfig {
        return AppConfig(version: 1, manifestFrequency: 1, decoyProbability: 1)
    }
    
    func register() {
        
    }
    
    func postKeys() {
        
    }
    
    func postStopKeys() {
        
    }
    
    
    
    init(networkManager:NetworkManaging) {
        self.networkManager = networkManager
    }
    
    private let networkManager:NetworkManaging
}
