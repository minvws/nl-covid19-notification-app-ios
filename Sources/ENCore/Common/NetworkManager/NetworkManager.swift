/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import ZIPFoundation

enum NetworkManagerError: Error {
    case emptyResponse
    case other(Error) // TODO: Map correctly
}

final class NetworkManager: NetworkManaging {

    init(configuration: NetworkConfiguration, networkResponseHandler: NetworkResponseProviderHandling, urlSession: URLSession = URLSession.shared) {
        self.configuration = configuration
        self.session = urlSession
        self.networkResponseHandler = networkResponseHandler
        
        // initialize json decoder with custom decoding strategy
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.keyDecodingStrategy = .convertFromUpperCamelCase
    }

    // MARK: CDN

    // Content retrieved via CDN.

    /// Fetches manifest from server with all available parameters
    /// - Parameter completion: return
    func getManifest(completion: @escaping (Result<Manifest, NetworkManagerError>) -> ()) {
        session.download(self.configuration.manifestUrl, contentType: self.configuration.contentType) { url, response, error in
            do {
                // get bin file and convert to object
                let data = try self.networkResponseHandler.handleReturnData(url: url, response: response, error: error)
                let manifest = try self.jsonDecoder.decode(Manifest.self, from: data)
                completion(.success(manifest))
            } catch {
                completion(.failure(.other(error)))
            }
        }
    }

    /// Fetched the global app config which contains version number, manifest polling frequence and decoy probability
    /// - Parameter completion: completion description
    func getAppConfig(appConfig: String, completion: @escaping (Result<AppConfig, NetworkManagerError>) -> ()) {
        session.download(self.configuration.appConfigUrl(param: appConfig), contentType: self.configuration.contentType) { url, response, error in
            do {
                // get bin file and convert to object
                let data = try self.networkResponseHandler.handleReturnData(url: url, response: response, error: error)
                let appConfig = try self.jsonDecoder.decode(AppConfig.self, from: data)
                completion(.success(appConfig))
            } catch {
                completion(.failure(.other(error)))
            }
        }
    }

    /// Fetches risk parameters used by the ExposureManager
    /// - Parameter completion: success or fail
    func getRiskCalculationParameters(appConfig: String, completion: @escaping (Result<RiskCalculationParameters, NetworkManagerError>) -> ()) {
        session.download(self.configuration.riskCalculationParametersUrl(param: appConfig), contentType: self.configuration.contentType) {
            url, response, error in
            do {
                // get bin file and convert to object
                let data = try self.networkResponseHandler.handleReturnData(url: url, response: response, error: error)
                let riskCalculationParams = try self.jsonDecoder.decode(RiskCalculationParameters.self, from: data)
                completion(.success(riskCalculationParams))
            } catch {
                completion(.failure(.other(error)))
            }
        }
    }

    /// Fetches TEKS
    /// - Parameters:
    ///   - id: id of the exposureKeySet
    ///   - completion: executed on complete or failure
    func getDiagnosisKeys(_ id: String, completion: @escaping (Result<[URL], NetworkManagerError>) -> ()) {
        session.download(self.configuration.exposureKeySetUrl(param: id), contentType: self.configuration.contentType) { url, response, error in
            do {
                let urls = try self.networkResponseHandler.handleReturnUrls(url: url, response: response, error: error)
                completion(.success(urls))
            } catch {
                completion(.failure(.other(error)))
            }
        }
    }

    /// Upload diagnosis keys (TEKs) to the server
    /// - Parameters:
    ///   - diagnosisKeys: Contains all diagnosisKeys available
    ///   - completion: completion nil if succes else error
    func postKeys(diagnosisKeys: DiagnosisKeys, completion: @escaping (NetworkManagerError?) -> ()) {
        session.post(self.configuration.postKeysUrl, object: diagnosisKeys) { data, response, error in
            completion(error.map { NetworkManagerError.other($0) })
        }
    }

    /// Upload decoy keys to the server
    /// - Parameters:
    ///   - diagnosisKeys: Contains all diagnosisKeys available
    ///   - completion: completion nil if succes else error
    func postStopKeys(diagnosisKeys: DiagnosisKeys, completion: @escaping (NetworkManagerError?) -> ()) {
        session.post(self.configuration.postKeysUrl, object: diagnosisKeys) { data, response, error in
            completion(error.map { NetworkManagerError.other($0) })
        }
    }

    /// Exchange a secret with the server so we can sign our keys
    /// - Parameters:
    ///   - register: Contains confirmation key
    ///   - completion: completion
    func postRegister(register: RegisterRequest, completion: @escaping (Result<LabInformation, NetworkManagerError>) -> ()) {
        session.post(self.configuration.registerUrl, object: register) { data, response, error in
            if let error = error {
                completion(.failure(.other(error)))
                return
            }

            do {
                guard let data = data else {
                    throw NetworkManagerError.emptyResponse
                }

                let labInformation = try JSONDecoder().decode(LabInformation.self, from: data)
                completion(.success(labInformation))
            } catch {
                completion(.failure(.other(error)))
            }
        }
    }

    private let configuration: NetworkConfiguration
    private let session: URLSession
    private let networkResponseHandler: NetworkResponseProviderHandling
    private let jsonDecoder: JSONDecoder
}
