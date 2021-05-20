/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import UIKit

enum URLSessionIdentifier: String {
    case keysetURLSession
}

final class NetworkManager: NetworkManaging, Logging {

    private lazy var keySetURLSession: URLSessionProtocol? = {
        let config = URLSessionConfiguration.background(withIdentifier: URLSessionIdentifier.keysetURLSession.rawValue)
        config.sessionSendsLaunchEvents = true        
        return urlSessionBuilder.build(configuration: config, delegate: sessionDelegate, delegateQueue: nil)
    }()
    
    init(configurationProvider: NetworkConfigurationProvider,
         responseHandlerProvider: NetworkResponseHandlerProvider,
         storageController: StorageControlling,
         session: URLSessionProtocol,
         sessionDelegate: URLSessionDelegateProtocol?,
         urlSessionBuilder: URLSessionBuilding) {
        self.configurationProvider = configurationProvider
        self.responseHandlerProvider = responseHandlerProvider
        self.storageController = storageController
        self.session = session
        self.sessionDelegate = sessionDelegate
        self.urlSessionBuilder = urlSessionBuilder
    }

    // MARK: CDN

    // Content retrieved via CDN.

    /// Fetches manifest from server with all available parameters
    /// - Parameter completion: return
    func getManifest(completion: @escaping (Result<Manifest, NetworkError>) -> ()) {
        let expectedContentType = HTTPContentType.zip
        let headers = [HTTPHeaderKey.acceptedContentType: expectedContentType.rawValue]
        let url = configuration.manifestUrl
        let urlRequest = constructRequest(url: url, method: .GET, headers: headers)

        downloadAndDecodeURL(withURLRequest: urlRequest, decodeAsType: Manifest.self, completion: completion)
    }

    /// Fetches the treatment perspective message from server
    /// - Parameters:
    ///   - id: id of the resourceBundleId
    ///   - completion: executed on complete or failure
    func getTreatmentPerspective(identifier: String, completion: @escaping (Result<TreatmentPerspective, NetworkError>) -> ()) {
        let expectedContentType = HTTPContentType.json
        let headers = [HTTPHeaderKey.acceptedContentType: expectedContentType.rawValue]
        let url = configuration.getTreatmentPerspectiveUrl(identifier: identifier)
        let urlRequest = constructRequest(url: url, method: .GET, headers: headers)

        downloadAndDecodeURL(withURLRequest: urlRequest, decodeAsType: TreatmentPerspective.self, completion: completion)
    }

    /// Fetched the global app config which contains version number, manifest polling frequence and decoy probability
    /// - Parameter completion: completion description
    func getAppConfig(appConfig: String, completion: @escaping (Result<AppConfig, NetworkError>) -> ()) {
        let expectedContentType = HTTPContentType.zip
        let headers = [HTTPHeaderKey.acceptedContentType: expectedContentType.rawValue]
        let url = configuration.appConfigUrl(identifier: appConfig)
        let urlRequest = constructRequest(url: url, method: .GET, headers: headers)

        downloadAndDecodeURL(withURLRequest: urlRequest, decodeAsType: AppConfig.self, completion: completion)
    }

    /// Fetches risk parameters used by the ExposureManager
    /// - Parameter completion: success or fail
    func getRiskCalculationParameters(identifier: String, completion: @escaping (Result<RiskCalculationParameters, NetworkError>) -> ()) {
        let expectedContentType = HTTPContentType.zip
        let headers = [HTTPHeaderKey.acceptedContentType: expectedContentType.rawValue]
        let url = configuration.riskCalculationParametersUrl(identifier: identifier)
        let urlRequest = constructRequest(url: url, method: .GET, headers: headers)

        downloadAndDecodeURL(withURLRequest: urlRequest, decodeAsType: RiskCalculationParameters.self, completion: completion)
    }

    /// Fetches TEKS
    /// - Parameters:
    ///   - id: id of the exposureKeySet
    ///   - completion: executed on complete or failure
    func getExposureKeySet(identifier: String, completion: @escaping (Result<URL, NetworkError>) -> ()) {
        let expectedContentType = HTTPContentType.zip
        let headers = [HTTPHeaderKey.acceptedContentType: expectedContentType.rawValue]
        let url = configuration.exposureKeySetUrl(identifier: identifier)
        let urlRequest = constructRequest(url: url, method: .GET, headers: headers)

        download(request: urlRequest) { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(result):
                self
                    .responseToLocalUrl(for: result.0, url: result.1, backgroundThreadIfPossible: true)
                    .subscribe { event in
                        switch event {

                        case let .success(data):
                            completion(.success(data))
                            self.logDebug("NetworkManager.getExposureKeySet completed")
                        case let .failure(error):
                            self.logError("Error downloading from url: \(result.1): \(error)")
                            completion(.failure(error.asNetworkError))
                        }
                    }
                    .disposed(by: self.disposeBag)
            }
        }
    }
    
    func getExposureKeySetsInBackground(identifiers: [String]) {
        
        logTrace()
        
        guard let keySetURLSession = keySetURLSession else {
            self.logError("Unable to download keysets. URLSession could not be constructed")
            return
        }
        
        keySetURLSession.getAllURLSessionTasks { (existingTasks) in
            
            let existingURLS = existingTasks.compactMap { $0.originalRequest?.url }
            
            self.logDebug("Currently active keyset downloads: \n\(existingURLS.compactMap { $0.absoluteString }.joined(separator: "\n"))")
            
            let backgroundTasks: [URLSessionDownloadTaskProtocol] = identifiers.compactMap { identifier in
                    
                let expectedContentType = HTTPContentType.zip
                let headers = [HTTPHeaderKey.acceptedContentType: expectedContentType.rawValue]
                
                guard let url = self.configuration.exposureKeySetUrl(identifier: identifier) else {
                    self.logError("Unable to create exposureKeySetUrl for identifier \(identifier) ")
                    return nil
                }
                
                guard !existingURLS.contains(url) else {
                    self.logDebug("download task already created for URL: \(url)")
                    return nil
                }
                
                let urlRequest = self.constructRequest(url: url, method: .GET, headers: headers)
                
                guard case let .success(request) = urlRequest else {
                    return nil
                }
                
                var backgroundTask = keySetURLSession.urlSessionDownloadTask(with: request)
                backgroundTask.countOfBytesClientExpectsToSend = 200
                backgroundTask.countOfBytesClientExpectsToReceive = 500 * 1024 // 500KB
                return backgroundTask
            }
            
            backgroundTasks.forEach { (task) in
                task.resume()
            }
            
            self.logDebug("Triggered background downloads for keysets: \n\(backgroundTasks.compactMap { $0.originalRequest?.url?.absoluteString }.joined(separator: "\n"))")
        }
    }
    
    func receiveURLSessionBackgroundCompletionHandler(completionHandler: @escaping () -> ()) {
        (sessionDelegate as? NetworkManagerURLSessionDelegate)?.urlSessionBackgroundCompletionHandler = completionHandler
    }

    /// Upload diagnosis keys (TEKs) to the server
    /// - Parameters:
    ///   - request: PostKeysRequest
    ///   - signature: Signature to add a queryString parameter
    ///   - completion: completion nil if succes else error
    func postKeys(request: PostKeysRequest, signature: String, completion: @escaping (NetworkError?) -> ()) {
        let expectedContentType = HTTPContentType.json
        let headers = [HTTPHeaderKey.acceptedContentType: expectedContentType.rawValue]

        let urlRequest = constructRequest(url: configuration.postKeysUrl(signature: signature),
                                          method: .POST,
                                          body: request,
                                          headers: headers)

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
        let expectedContentType = HTTPContentType.json
        let headers = [HTTPHeaderKey.acceptedContentType: expectedContentType.rawValue]

        let urlRequest = constructRequest(url: configuration.stopKeysUrl(signature: signature),
                                          method: .POST,
                                          body: request,
                                          headers: headers)

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
        let expectedContentType = HTTPContentType.json
        let headers = [HTTPHeaderKey.acceptedContentType: expectedContentType.rawValue]
        let url = configuration.registerUrl
        let urlRequest = constructRequest(url: url, method: .POST, body: request, headers: headers)

        data(request: urlRequest) { result in

            switch result {
            case let .failure(error):
                completion(.failure(error))

            case let .success(result):

                self.decodeJson(type: LabInformation.self, data: result.1)
                    .subscribe { event in
                        switch event {
                        case let .success(labInformation):
                            self.logDebug("Posting to url \(String(describing: url)) completed")
                            completion(.success(labInformation))
                        case let .failure(error):
                            self.logError("Error posting to url: \(String(describing: url)): \(error)")
                            completion(.failure(error.asNetworkError))
                        }
                    }
                    .disposed(by: self.disposeBag)
            }
        }
    }

    // MARK: - Construct Request

    private func constructRequest(url: URL?,
                                  method: HTTPMethod = .GET,
                                  body: Encodable? = nil,
                                  headers: [HTTPHeaderKey: String] = [:]) -> Result<URLRequest, NetworkError> {
        guard let url = url else {
            return .failure(.invalidRequest)
        }

        var request = URLRequest(url: url,
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 10)
        request.httpMethod = method.rawValue

        let defaultHeaders = [
            HTTPHeaderKey.contentType: HTTPContentType.json.rawValue
        ]

        defaultHeaders.forEach { header, value in
            request.addValue(value, forHTTPHeaderField: header.rawValue)
        }

        headers.forEach { header, value in
            request.addValue(value, forHTTPHeaderField: header.rawValue)
        }

        if let body = body.flatMap({ try? self.jsonEncoder.encode(AnyEncodable($0)) }) {
            request.httpBody = body
        }

        logDebug("--REQUEST--")
        if let url = request.url { logDebug(url.debugDescription) }
        if let allHTTPHeaderFields = request.allHTTPHeaderFields { logDebug(allHTTPHeaderFields.debugDescription) }
        if let httpBody = request.httpBody { logDebug(String(data: httpBody, encoding: .utf8)!) }
        logDebug("--END REQUEST--")

        return .success(request)
    }

    // MARK: - Download Files

    private func downloadAndDecodeURL<T: Decodable>(withURLRequest urlRequest: Result<URLRequest, NetworkError>,
                                                    decodeAsType modelType: T.Type,
                                                    backgroundThreadIfPossible: Bool = false,
                                                    completion: @escaping (Result<T, NetworkError>) -> ()) {

        download(request: urlRequest) { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(result):
                self
                    .responseToData(for: result.0, url: result.1, backgroundThreadIfPossible: backgroundThreadIfPossible)
                    .flatMap {
                        self.decodeJson(type: modelType, data: $0)
                    }
                    .subscribe { event in
                        switch event {
                        case let .success(data):
                            completion(.success(data))
                        case let .failure(error):
                            self.logError("Error downloading from url: \(result.1): \(error)")
                            completion(.failure(error.asNetworkError))
                        }
                    }
                    .disposed(by: self.disposeBag)
            }
        }
    }

    fileprivate func download(request: Result<URLRequest, NetworkError>, completion: @escaping (Result<(URLResponse, URL), NetworkError>) -> ()) {
        switch request {
        case let .success(request):
            download(request: request, completion: completion)
        case let .failure(error):
            completion(.failure(error))
        }
    }

    fileprivate func download(request: URLRequest, completion: @escaping (Result<(URLResponse, URL), NetworkError>) -> ()) {
        session.resumableDataTask(with: request) { data, response, error in
            let localUrl: URL?

            if let data = data {
                localUrl = self.write(data: data)
            } else {
                localUrl = nil
            }

            self.handleNetworkResponse(localUrl, response: response, error: error, completion: completion)
        }.resume()
    }

    private func write(data: Data) -> URL? {
        let uuid = UUID().uuidString
        let temporaryUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(uuid)

        do {
            try data.write(to: temporaryUrl)
            return temporaryUrl
        } catch {
            return nil
        }
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
        session.resumableDataTask(with: request) { data, response, error in
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

        logDebug("--RESPONSE--")
        if let response = response as? HTTPURLResponse {
            logDebug("Finished response to URL \(response.url?.absoluteString ?? "") with status \(response.statusCode)")

            let headers = response.allHeaderFields.map { header, value in
                return String("\(header): \(value)")
            }.joined(separator: "\n")

            logDebug("Response headers: \n\(headers)")
        } else if let error = error {
            logDebug("Error with response: \(error)")
        }

        logDebug("--END RESPONSE--")

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

    /// Checks for valid HTTPResponse and status codes
    private func inspect(response: URLResponse) -> NetworkError? {
        guard let response = response as? HTTPURLResponse else {
            return .invalidResponse
        }

        switch response.statusCode {
        case 200 ... 299:
            return nil
        case 304:
            return .responseCached
        case 300 ... 399:
            return .redirection
        case 400 ... 499:
            return .resourceNotFound
        case 500 ... 599:
            return .serverError
        default:
            return .invalidResponse
        }
    }

    /// Unzips, verifies signature and reads response in memory
    private func responseToData(for response: URLResponse, url: URL, backgroundThreadIfPossible: Bool = false) -> Single<Data> {
        let localUrl = responseToLocalUrl(for: response, url: url, backgroundThreadIfPossible: backgroundThreadIfPossible)

        let readFromDiskResponseHandler = responseHandlerProvider.readFromDiskResponseHandler
        if readFromDiskResponseHandler.isApplicable(for: response, input: url) {
            return localUrl
                .flatMap { localUrl in readFromDiskResponseHandler.process(response: response, input: localUrl) }
        } else {
            return .error(NetworkResponseHandleError.cannotDeserialize)
        }
    }

    private func responseToLocalUrl(for response: URLResponse, url: URL, backgroundThreadIfPossible: Bool = false) -> Single<URL> {
        var localUrl = Single<URL>.just(url)

        if backgroundThreadIfPossible, UIApplication.shared.applicationState != .background {
            localUrl = localUrl
                .observe(on: concurrentUtilityScheduler)
        }

        // unzip
        let unzipResponseHandler = responseHandlerProvider.unzipNetworkResponseHandler
        if unzipResponseHandler.isApplicable(for: response, input: url) {
            localUrl = localUrl
                .flatMap { localUrl in unzipResponseHandler.process(response: response, input: localUrl) }
        }

        // verify signature
        let verifySignatureResponseHandler = responseHandlerProvider.verifySignatureResponseHandler
        if verifySignatureResponseHandler.isApplicable(for: response, input: url) {
            localUrl = localUrl
                .flatMap { localUrl in verifySignatureResponseHandler.process(response: response, input: localUrl) }
        }

        return localUrl
    }

    /// Utility function to decode JSON
    private func decodeJson<Object: Decodable>(type: Object.Type, data: Data) -> Single<Object> {

        return .create { observer in

            do {
                let object = try self.jsonDecoder.decode(Object.self, from: data)
                self.logDebug("Response Object: \(object)")
                observer(.success(object))
            } catch let DecodingError.keyNotFound(key, context) {
                self.logError("could not find key \(key) in JSON: \(context.debugDescription)")
                observer(.failure(NetworkResponseHandleError.cannotDeserialize))
            } catch let DecodingError.valueNotFound(type, context) {
                self.logError("could not find type \(type) in JSON: \(context.debugDescription)")
                observer(.failure(NetworkResponseHandleError.cannotDeserialize))
            } catch let DecodingError.typeMismatch(type, context) {
                self.logError("type mismatch for type \(type) in JSON: \(context.debugDescription)")
                observer(.failure(NetworkResponseHandleError.cannotDeserialize))
            } catch let DecodingError.dataCorrupted(context) {
                self.logError("data found to be corrupted in JSON: \(context.debugDescription)")
                observer(.failure(NetworkResponseHandleError.cannotDeserialize))
            } catch let error as NSError {
                NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
                observer(.failure(NetworkResponseHandleError.cannotDeserialize))
            }

            return Disposables.create()
        }
    }

    // MARK: - Private

    private let configurationProvider: NetworkConfigurationProvider
    private let session: URLSessionProtocol
    private let sessionDelegate: URLSessionDelegateProtocol? // hold on to delegate to prevent deallocation
    private let responseHandlerProvider: NetworkResponseHandlerProvider
    private let storageController: StorageControlling
    private let urlSessionBuilder: URLSessionBuilding

    private var configuration: NetworkConfiguration {
        return configurationProvider.configuration
    }

    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromUpperCamelCase

        return decoder
    }()

    private lazy var jsonEncoder = JSONEncoder()
    private var disposeBag = DisposeBag()
    private let concurrentUtilityScheduler = ConcurrentDispatchQueueScheduler(qos: .utility)
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

extension Error {
    var asNetworkError: NetworkError {
        guard let networkResponseHandleError = self as? NetworkResponseHandleError else {
            return .errorConversionError
        }

        switch networkResponseHandleError {
        case .cannotDeserialize:
            return .invalidResponse
        case .cannotUnzip:
            return .invalidResponse
        case .invalidSignature:
            return .invalidResponse
        }
    }
}

extension Error {
    var asExposureDataError: ExposureDataError {
        guard let networkError = self as? NetworkError else {
            return ExposureDataError.internalError
        }
        return networkError.asExposureDataError
    }
}
