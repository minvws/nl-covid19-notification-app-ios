/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

final class NetworkController: NetworkControlling {

    init(networkManager: NetworkManaging,
         cryptoUtility: CryptoUtility) {
        self.networkManager = networkManager
        self.cryptoUtility = cryptoUtility
    }

    // MARK: - NetworkControlling

    var applicationManifest: AnyPublisher<ApplicationManifest, NetworkError> {
        return Deferred {
            Future { promise in
                self.networkManager.getManifest { result in
                    promise(result.map { $0.asApplicationManifest })
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
                self.networkManager.getExposureKeySet(identifier: identifier) { result in
                    promise(result
                        .map { localUrl in (identifier, localUrl) }
                    )
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func requestLabConfirmationKey() -> AnyPublisher<LabConfirmationKey, NetworkError> {
        return Deferred {
            Future { promise in
                let padding = self.cryptoUtility.randomBytes(ofLength: 32).base64EncodedString()
                let request = RegisterRequest(padding: padding)

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

    func postKeys(keys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> AnyPublisher<(), NetworkError> {
        return Deferred {
            Future { promise in
                let padding = self.cryptoUtility.randomBytes(ofLength: 32).base64EncodedString()
                let request = PostKeysRequest(keys: keys.map { $0.asTemporaryKey },
                                              bucketID: labConfirmationKey.bucketIdentifier.base64EncodedString(),
                                              padding: padding)

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

    // MARK: - Private

    private let networkManager: NetworkManaging
    private let cryptoUtility: CryptoUtility
}
