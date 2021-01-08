/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation
import RxSwift

final class NetworkController: NetworkControlling, Logging {

    // MARK: - Init

    init(networkManager: NetworkManaging,
         cryptoUtility: CryptoUtility) {
        self.networkManager = networkManager
        self.cryptoUtility = cryptoUtility
    }

    // MARK: - NetworkControlling

    var applicationManifest: Observable<ApplicationManifest> {
        let observable: Observable<ApplicationManifest> = .create { [weak self] observer in
            guard let strongSelf = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            strongSelf.networkManager.getManifest { result in
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

        return observable.observe(on: MainScheduler.instance)
    }

    func treatmentPerspective(identifier: String) -> Observable<TreatmentPerspective> {
        return .create { observer in
            self.networkManager.getTreatmentPerspective(identifier: identifier) { result in
                switch result {
                case let .failure(error):
                    observer.onError(error)
                case let .success(treatmentPerspective):
                    observer.onNext(treatmentPerspective)
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        }
    }

    func applicationConfiguration(identifier: String) -> Observable<ApplicationConfiguration> {
        return .create { (observer) -> Disposable in
            self.networkManager.getAppConfig(appConfig: identifier) { result in
                switch result {
                case let .success(configuration):
                    observer.onNext(configuration.asApplicationConfiguration(identifier: identifier))
                    observer.onCompleted()
                case let .failure(error):
                    observer.onError(error)
                }
            }

            return Disposables.create()
        }
    }

    func exposureRiskConfigurationParameters(identifier: String) -> Observable<ExposureRiskConfiguration> {
        return .create { observer in
            self.networkManager.getRiskCalculationParameters(identifier: identifier) { result in
                switch result {
                case let .failure(error):
                    observer.onError(error)
                case let .success(parameters):
                    observer.onNext(parameters.asExposureRiskConfiguration(identifier: identifier))
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        }
    }

    func fetchExposureKeySet(identifier: String) -> Observable<(String, URL)> {
        return .create { (observer) -> Disposable in

            let start = CFAbsoluteTimeGetCurrent()

            self.networkManager.getExposureKeySet(identifier: identifier) { result in

                let diff = CFAbsoluteTimeGetCurrent() - start
                print("Fetching ExposureKeySet Took \(diff) seconds")

                switch result {
                case let .success(keySetURL):
                    observer.onNext((identifier, keySetURL))
                    observer.onCompleted()
                case let .failure(error):
                    observer.onError(error)
                }
            }

            return Disposables.create()
        }
    }

    func requestLabConfirmationKey(padding: Padding) -> Observable<LabConfirmationKey> {
        let observable = Observable<LabConfirmationKey>.create { observer in

            let preRequest = PreRegisterRequest()

            let generatedPadding = self.generatePadding(forObject: preRequest, padding: padding)
            let request = RegisterRequest(padding: generatedPadding)

            self.networkManager.postRegister(request: request) { result in

                guard case let .success(labInformation) = result,
                    let labConfirmationKey = labInformation.asLabConfirmationKey else {
                    observer.onError(NetworkError.invalidResponse)
                    return
                }

                observer.onNext(labConfirmationKey)
                observer.onCompleted()
            }

            return Disposables.create()
        }

        return observable.subscribe(on: MainScheduler.instance)
    }

    func postKeys(keys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey, padding: Padding) -> Single<()> {

        return .create { observer in

            let preRequest = PrePostKeysRequest(keys: keys.map { $0.asTemporaryKey }, bucketId: labConfirmationKey.bucketIdentifier)
            let generatedPadding = self.generatePadding(forObject: preRequest, padding: padding)

            let request = PostKeysRequest(keys: keys.map { $0.asTemporaryKey },
                                          bucketId: labConfirmationKey.bucketIdentifier,
                                          padding: generatedPadding)

            guard let requestData = try? JSONEncoder().encode(request) else {
                observer(.failure(NetworkError.encodingError))
                return Disposables.create()
            }

            let signature = self.cryptoUtility
                .signature(forData: requestData, key: labConfirmationKey.confirmationKey)
                .base64EncodedString()

            let completion: (NetworkError?) -> () = { error in
                if let error = error {
                    observer(.failure(error))
                    return
                }

                observer(.success(()))
            }

            self.networkManager.postKeys(request: request,
                                         signature: signature,
                                         completion: completion)

            return Disposables.create()
        }
    }

    func stopKeys(padding: Padding) -> Single<()> {
        return .create { observer in

            let preRequest = PrePostKeysRequest(keys: [], bucketId: Data())
            let generatedPadding = self.generatePadding(forObject: preRequest, padding: padding)

            let request = PostKeysRequest(keys: [],
                                          bucketId: Data(),
                                          padding: generatedPadding)

            guard let requestData = try? JSONEncoder().encode(request) else {
                observer(.failure(NetworkError.encodingError))
                return Disposables.create()
            }

            let signature = self.cryptoUtility
                .signature(forData: requestData, key: Data())
                .base64EncodedString()

            let completion: (NetworkError?) -> () = { error in
                if let error = error {
                    observer(.failure(error))
                    return
                }

                observer(.success(()))
            }

            self.networkManager.postStopKeys(request: request,
                                             signature: signature,
                                             completion: completion)

            return Disposables.create()
        }
    }

    // MARK: - Private

    private let networkManager: NetworkManaging
    private let cryptoUtility: CryptoUtility

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
