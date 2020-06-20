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

    var exposureKeySetProvider: Future<ExposureKeySetProvider, NetworkError> {
        return Future { promise in
            promise(.failure(.serverNotReachable))
        }
    }

    var exposureRiskCalculationParameters: Future<ExposureRiskCalculationParameters, NetworkError> {
        return Future { promise in
            promise(.failure(.serverNotReachable))
        }
    }

    var resourceBundle: Future<ResourceBundle, NetworkError> {
        return Future { promise in
            promise(.failure(.serverNotReachable))
        }
    }

    func requestLabConfirmationKey() -> AnyPublisher<LabConfirmationKey, NetworkError> {
        return Future { promise in
            let request = RegisterRequest(padding: "5342fds89erwtsdf")

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
        .eraseToAnyPublisher()
    }

    func postKeys(keys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> AnyPublisher<(), NetworkError> {
        return Future { promise in
            let request = PostKeysRequest(keys: keys.map { $0.asTemporaryKey },
                                          bucketID: labConfirmationKey.bucketIdentifier.base64EncodedString(),
                                          padding: "aGFsbG8gcmVpbmllci4gYWxzIGplIGRpdCBsZWVzdCwgemVnIGJvZSEgb3Agd2ViZXgK")

            guard let requestData = try? JSONEncoder().encode(request) else {
                promise(.failure(.encodingError))
                return
            }

            let signature = self.cryptoUtility
                .signature(forData: requestData, key: labConfirmationKey.confirmationKey)
                .base64EncodedString()

            print(signature)

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
        .eraseToAnyPublisher()
    }

    // MARK: - Private

    private let networkManager: NetworkManaging
    private let cryptoUtility: CryptoUtility
}
