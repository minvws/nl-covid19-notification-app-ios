/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation
import Reachability
import RxSwift

final class NetworkController: NetworkControlling, Logging {

    // MARK: - Init

    init(networkManager: NetworkManaging,
         cryptoUtility: CryptoUtility,
         mutableNetworkStatusStream: MutableNetworkStatusStreaming) {
        self.networkManager = networkManager
        self.cryptoUtility = cryptoUtility
        self.mutableNetworkStatusStream = mutableNetworkStatusStream
    }

    // MARK: - NetworkControlling

    var applicationManifest: Observable<ApplicationManifest> {
        return .create { [weak self] observer in
            self?.networkManager.getManifest { result in
                switch result {
                case let .failure(error):
                    observer.onError(error)
                case let .success(manifest):
                    observer.onNext(manifest.asApplicationManifest)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    func treatmentPerspective(identifier: String) -> AnyPublisher<TreatmentPerspective, NetworkError> {
        return Deferred {
            Future { promise in
                self.networkManager.getTreatmentPerspective(identifier: identifier) { result in
                    promise(result)
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func applicationConfiguration(identifier: String) -> AnyPublisher<ApplicationConfiguration, NetworkError> {
        return Deferred {
            Future { promise in
                self.networkManager.getAppConfig(appConfig: identifier) { result in
                    promise(result.map { $0.asApplicationConfiguration(identifier: identifier) })
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func exposureRiskConfigurationParameters(identifier: String) -> AnyPublisher<ExposureRiskConfiguration, NetworkError> {
        return Deferred {
            Future { promise in
                self.networkManager.getRiskCalculationParameters(identifier: identifier) { result in
                    promise(result
                        .map { $0.asExposureRiskConfiguration(identifier: identifier) }
                    )
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func fetchExposureKeySet(identifier: String) -> AnyPublisher<(String, URL), NetworkError> {
        return Deferred {
            Future { promise in
                let start = CFAbsoluteTimeGetCurrent()

                self.networkManager.getExposureKeySet(identifier: identifier) { result in

                    let diff = CFAbsoluteTimeGetCurrent() - start
                    print("Fetching ExposureKeySet Took \(diff) seconds")

                    promise(result
                        .map { localUrl in (identifier, localUrl) }
                    )
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func requestLabConfirmationKey(padding: Padding) -> AnyPublisher<LabConfirmationKey, NetworkError> {
        return Deferred {
            Future { promise in
                let preRequest = PreRegisterRequest()

                let generatedPadding = self.generatePadding(forObject: preRequest, padding: padding)
                let request = RegisterRequest(padding: generatedPadding)

                self.networkManager.postRegister(request: request) { result in

                    let convertLabConfirmationKey: (LabInformation) -> Result<LabConfirmationKey, NetworkError> = { labInformation in
                        guard let labConfirmationKey = labInformation.asLabConfirmationKey else {
                            return .failure(.invalidResponse)
                        }

                        return .success(labConfirmationKey)
                    }

                    promise(result
                        .flatMap(convertLabConfirmationKey)
                    )
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func postKeys(keys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey, padding: Padding) -> AnyPublisher<(), NetworkError> {
        return Deferred {
            Future { promise in

                let preRequest = PrePostKeysRequest(keys: keys.map { $0.asTemporaryKey }, bucketId: labConfirmationKey.bucketIdentifier)
                let generatedPadding = self.generatePadding(forObject: preRequest, padding: padding)

                let request = PostKeysRequest(keys: keys.map { $0.asTemporaryKey },
                                              bucketId: labConfirmationKey.bucketIdentifier,
                                              padding: generatedPadding)

                guard let requestData = try? JSONEncoder().encode(request) else {
                    promise(.failure(.encodingError))
                    return
                }

                let signature = self.cryptoUtility
                    .signature(forData: requestData, key: labConfirmationKey.confirmationKey)
                    .base64EncodedString()

                let completion: (NetworkError?) -> () = { error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }

                    promise(.success(()))
                }

                self.networkManager.postKeys(request: request,
                                             signature: signature,
                                             completion: completion)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func stopKeys(padding: Padding) -> AnyPublisher<(), NetworkError> {
        return Deferred {
            Future { promise in

                let preRequest = PrePostKeysRequest(keys: [], bucketId: Data())
                let generatedPadding = self.generatePadding(forObject: preRequest, padding: padding)

                let request = PostKeysRequest(keys: [],
                                              bucketId: Data(),
                                              padding: generatedPadding)

                guard let requestData = try? JSONEncoder().encode(request) else {
                    promise(.failure(.encodingError))
                    return
                }

                let signature = self.cryptoUtility
                    .signature(forData: requestData, key: Data())
                    .base64EncodedString()

                let completion: (NetworkError?) -> () = { error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }

                    promise(.success(()))
                }

                self.networkManager.postStopKeys(request: request,
                                                 signature: signature,
                                                 completion: completion)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func startObservingNetworkReachability() {
        if reachability == nil {
            do {
                self.reachability = try Reachability()
            } catch {
                logError("Unable to instantiate Reachability")
            }
        }
        reachability?.whenReachable = { [weak self] status in
            self?.mutableNetworkStatusStream.update(isReachable: status.connection != .unavailable)
        }
        reachability?.whenUnreachable = { [weak self] status in
            self?.mutableNetworkStatusStream.update(isReachable: !(status.connection == .unavailable))
        }

        do {
            try reachability?.startNotifier()
        } catch {
            logError("Unable to start Reachability")
        }
    }

    func stopObservingNetworkReachability() {
        guard let reachability = reachability else {
            return
        }
        reachability.stopNotifier()
    }

    // MARK: - Private

    private let networkManager: NetworkManaging
    private let cryptoUtility: CryptoUtility
    private var reachability: Reachability?
    private let mutableNetworkStatusStream: MutableNetworkStatusStreaming

    private func generatePadding<T: Encodable>(forObject object: T, padding: Padding) -> String {
        func randomString(length: Int) -> String {
            guard length > 0 else {
                return ""
            }
            let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            assert(letters.count == 52)
            return String((0 ..< length).map { _ in letters.randomElement() ?? "a" })
        }

        let min = padding.minimumRequestSize
        let max = padding.maximumRequestSize

        let randomInt = Int.random(in: 0 ... 100)
        let messageSize: Int
        if randomInt == 0 {
            messageSize = Int.random(in: min ... max)
        } else {
            messageSize = Int.random(in: min ... (min + (max - min) / 100))
        }

        do {
            let length = try JSONEncoder().encode(object).count
            return randomString(length: messageSize - length)
        } catch {
            self.logError("Error encoding: \(error.localizedDescription)")
        }
        return randomString(length: min)
    }
}
