/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

final class NetworkManager: NetworkManaging {

    init(configuration: NetworkConfiguration,
         responseHandlerProvider: NetworkResponseHandlerProvider,
         urlSession: URLSession = URLSession.shared) {
        self.configuration = configuration
        self.session = urlSession
        self.responseHandlerProvider = responseHandlerProvider
    }

    // MARK: CDN

    // Content retrieved via CDN.

    /// Fetches manifest from server with all available parameters
    /// - Parameter completion: return
    func getManifest(completion: @escaping (Result<Manifest, NetworkError>) -> ()) {
        let urlRequest = constructRequest(url: configuration.manifestUrl,
                                          method: .GET)

        download(request: urlRequest) { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(result):
                let dataResult = self
                    .handleDataResponse(for: result.0, url: result.1)

                completion(dataResult
                    .flatMap(self.decodeJson(data:))
                    .mapError { $0.asNetworkError }
                )
            }
        }
    }

    /// Fetched the global app config which contains version number, manifest polling frequence and decoy probability
    /// - Parameter completion: completion description
    func getAppConfig(appConfig: String, completion: @escaping (Result<AppConfig, NetworkError>) -> ()) {
        let urlRequest = constructRequest(url: configuration.appConfigUrl(identifier: appConfig),
                                          method: .GET)

        download(request: urlRequest) { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(result):
                let dataResult = self
                    .handleDataResponse(for: result.0, url: result.1)

                completion(dataResult
                    .flatMap(self.decodeJson(data:))
                    .mapError { $0.asNetworkError }
                )
            }
        }
    }

    /// Fetches risk parameters used by the ExposureManager
    /// - Parameter completion: success or fail
    func getRiskCalculationParameters(appConfig: String, completion: @escaping (Result<RiskCalculationParameters, NetworkError>) -> ()) {
        let urlRequest = constructRequest(url: configuration.riskCalculationParametersUrl(identifier: appConfig),
                                          method: .GET)

        download(request: urlRequest) { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(result):
                let dataResult = self
                    .handleDataResponse(for: result.0, url: result.1)

                completion(dataResult
                    .flatMap(self.decodeJson(data:))
                    .mapError { $0.asNetworkError }
                )
            }
        }
    }

    /// Fetches TEKS
    /// - Parameters:
    ///   - id: id of the exposureKeySet
    ///   - completion: executed on complete or failure
    func getDiagnosisKeys(_ id: String, completion: @escaping (Result<[URL], NetworkError>) -> ()) {
        let urlRequest = constructRequest(url: configuration.exposureKeySetUrl(identifier: id),
                                          method: .GET)

        download(request: urlRequest) { result in
            // TODO: Interpret result
        }
    }

    /// Upload diagnosis keys (TEKs) to the server
    /// - Parameters:
    ///   - request: PostKeysRequest
    ///   - signature: Signature to add a queryString parameter
    ///   - completion: completion nil if succes else error
    func postKeys(request: PostKeysRequest, signature: String, completion: @escaping (NetworkError?) -> ()) {
        let urlRequest = constructRequest(url: configuration.postKeysUrl(signature: signature),
                                          method: .POST,
                                          body: request)

        data(request: urlRequest) { result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        }
    }

    /// Upload decoy keys to the server
    /// - Parameters:
    ///   - diagnosisKeys: Contains all diagnosisKeys available
    ///   - completion: completion nil if succes else error
    func postStopKeys(request: PostKeysRequest, signature: String, completion: @escaping (NetworkError?) -> ()) {
        let urlRequest = constructRequest(url: configuration.postKeysUrl(signature: signature),
                                          method: .POST,
                                          body: request)

        data(request: urlRequest) { result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        }
    }

    /// Exchange a secret with the server so we can sign our keys
    /// - Parameters:
    ///   - register: Contains confirmation key
    ///   - completion: completion
    func postRegister(request: RegisterRequest, completion: @escaping (Result<LabInformation, NetworkError>) -> ()) {
        let urlRequest = constructRequest(url: configuration.registerUrl, method: .POST, body: request)

        data(request: urlRequest) { result in
            completion(self.jsonResponseHandler(result: result))
        }
    }

    // MARK: - Construct Request

    private func constructRequest(url: URL?,
                                  method: HTTPMethod = .GET,
                                  body: Encodable? = nil,
                                  headers: [String: String] = [:]) -> Result<URLRequest, NetworkError> {
        guard let url = url else {
            return .failure(.invalidRequest)
        }

        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = method.rawValue

        let defaultHeaders = [
            HTTPHeaderKey.acceptedContentType.rawValue: configuration.expectedContentType.rawValue,
            HTTPHeaderKey.contentType.rawValue: HTTPContentType.json.rawValue
        ]

        request.allHTTPHeaderFields = defaultHeaders

        headers.forEach { header, value in
            request.addValue(value, forHTTPHeaderField: header)
        }

        if let body = body.map({ try? self.jsonEncoder.encode(AnyEncodable($0)) }) {
            request.httpBody = body
        }

        return .success(request)
    }

    // MARK: - Download Files

    fileprivate func download(request: Result<URLRequest, NetworkError>, completion: @escaping (Result<(URLResponse, URL), NetworkError>) -> ()) {
        switch request {
        case let .success(request):
            download(request: request, completion: completion)
        case let .failure(error):
            completion(.failure(error))
        }
    }

    fileprivate func download(request: URLRequest, completion: @escaping (Result<(URLResponse, URL), NetworkError>) -> ()) {
        session.downloadTask(with: request) { localUrl, response, error in
            self.handleNetworkResponse(localUrl,
                                       response: response,
                                       error: error,
                                       completion: completion)
        }
        .resume()
    }

    // MARK: - Download Data

    private func data(request: Result<URLRequest, NetworkError>, completion: @escaping (Result<(URLResponse, Data), NetworkError>) -> ()) {
        switch request {
        case let .success(request):
            data(request: request, completion: completion)
        case let .failure(error):
            completion(.failure(error))
        }
    }

    private func data(request: URLRequest, completion: @escaping (Result<(URLResponse, Data), NetworkError>) -> ()) {
        print(request)
        session.dataTask(with: request) { data, response, error in
            self.handleNetworkResponse(data,
                                       response: response,
                                       error: error,
                                       completion: completion)
        }
        .resume()
    }

    // MARK: - Utilities

    /// Checks for failures and inspects status code
    private func handleNetworkResponse<Object>(_ object: Object?,
                                               response: URLResponse?,
                                               error: Error?,
                                               completion: @escaping (Result<(URLResponse, Object), NetworkError>) -> ()) {
        if error != nil {
            completion(.failure(.invalidResponse))
            return
        }

        print(response)
        if let object = object as? Data {
            print(String(data: object, encoding: .utf8)!)
        }

        guard let response = response,
            let object = object else {
            completion(.failure(.invalidResponse))
            return
        }

        if let error = self.inspect(response: response) {
            completion(.failure(error))
            return
        }

        completion(.success((response, object)))
    }

    /// Unzips, verifies signature and reads response in memory
    private func handleDataResponse(for response: URLResponse, url: URL) -> Result<Data, NetworkResponseHandleError> {
        var localUrl = url

        // unzip
        let unzipResponseHandler = responseHandlerProvider.unzipNetworkResponseHandler
        if unzipResponseHandler.isApplicable(for: response, input: url) {
            do {
                localUrl = try unzipResponseHandler.process(response: response, input: localUrl)
            } catch {
                return .failure((error as? NetworkResponseHandleError) ?? .cannotDeserialize)
            }
        }

        // verify signature
        let verifySignatureResponseHandler = responseHandlerProvider.verifySignatureResponseHandler
        if verifySignatureResponseHandler.isApplicable(for: response, input: url) {
            do {
                localUrl = try verifySignatureResponseHandler.process(response: response, input: localUrl)
            } catch {
                return .failure((error as? NetworkResponseHandleError) ?? .cannotDeserialize)
            }
        }

        // read from disk
        let localData: Data

        let readFromDiskResponseHandler = responseHandlerProvider.readFromDiskResponseHandler
        if readFromDiskResponseHandler.isApplicable(for: response, input: url) {
            do {
                localData = try readFromDiskResponseHandler.process(response: response, input: localUrl)
            } catch {
                return .failure((error as? NetworkResponseHandleError) ?? .cannotDeserialize)
            }
        } else {
            return .failure(.cannotDeserialize)
        }

        return .success(localData)
    }

    /// Utility function to decode JSON
    private func decodeJson<Object: Decodable>(data: Data) -> Result<Object, NetworkResponseHandleError> {
        do {
            return .success(try jsonDecoder.decode(Object.self, from: data))
        } catch {
            return .failure(.cannotDeserialize)
        }
    }

    /// Response handler which decodes JSON
    private func jsonResponseHandler<Object: Decodable>(result: Result<(URLResponse, Data), NetworkError>) -> Result<Object, NetworkError> {
        return result
            .flatMap { result in
                self.decodeJson(data: result.1)
                    .mapError { $0.asNetworkError }
            }
    }

    /// Checks for valid HTTPResponse and status codes
    private func inspect(response: URLResponse) -> NetworkError? {
        guard let response = response as? HTTPURLResponse else {
            return .invalidResponse
        }

        switch response.statusCode {
        case 200 ... 299:
            return nil
        case 300 ... 399:
            return .responseCached
        case 400 ... 499:
            return .resourceNotFound
        case 500 ... 599:
            return .serverError
        default:
            return .invalidResponse
        }
    }

    // MARK: - Private

    private let configuration: NetworkConfiguration
    private let session: URLSession
    private let responseHandlerProvider: NetworkResponseHandlerProvider

    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromUpperCamelCase

        return decoder
    }()

    private lazy var jsonEncoder = JSONEncoder()
}

extension NetworkResponseHandleError {
    var asNetworkError: NetworkError {
        switch self {
        case .cannotDeserialize:
            return .invalidResponse
        case .cannotUnzip:
            return .invalidResponse
        case .invalidSignature:
            return .invalidResponse
        }
    }
}
