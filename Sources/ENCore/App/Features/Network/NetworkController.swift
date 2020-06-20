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

            self.networkManager.postRegister(register: request) { result in

                let convertLabConfirmationKey: (LabInformation) -> Result<LabConfirmationKey, NetworkError> = { labInformation in
                    guard let labConfirmationKey = labInformation.asLabConfirmationKey else {
                        return .failure(.invalidResponse)
                    }

                    return .success(labConfirmationKey)
                }

                promise(result
                    .mapError { error in error.asNetworkError }
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
                                          padding: "test".data(using: .utf8)!.base64EncodedString())

            guard let requestData = try? JSONEncoder().encode(request) else {
                promise(.failure(.encodingError))
                return
            }

            let signature = self.cryptoUtility
                .signature(forData: requestData, key: labConfirmationKey.confirmationKey.data(using: .utf8)!)
                .base64EncodedString()

            print(signature)

            let completion: (NetworkManagerError?) -> () = { error in
                if let error = error?.asNetworkError {
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

private extension NetworkManagerError {
    var asNetworkError: NetworkError {
        switch self {
        case .emptyResponse:
            return .invalidResponse
        case .invalidUrlArgument:
            return .encodingError
        case .other:
            return .invalidResponse
        }
    }
}
