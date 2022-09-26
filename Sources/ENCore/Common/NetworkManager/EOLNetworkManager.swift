/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

final class EOLNetworkManager: NetworkManaging {

    // MARK: CDN

    func getManifest(completion: @escaping (Result<Manifest, NetworkError>) -> ()) {
        completion(.success(Manifest(exposureKeySets: [], riskCalculationParameters: "", appConfig: "eol", resourceBundle: nil)))
    }

    func getTreatmentPerspective(identifier: String, completion: @escaping (Result<TreatmentPerspective, NetworkError>) -> ()) {
        completion(.failure(.invalidRequest))
    }

    func getAppConfig(appConfig: String, completion: @escaping (Result<AppConfig, NetworkError>) -> ()) {
        completion(.success(AppConfig(version: nil, manifestFrequency: nil, decoyProbability: nil, appStoreURL: nil, iOSMinimumVersion: nil, iOSMinimumVersionMessage: nil, iOSAppStoreURL: nil, requestMinimumSize: nil, requestMaximumSize: nil, repeatedUploadDelay: nil, coronaMelderDeactivated: "deactivated", coronaMelderDeactivatedTitle: nil, coronaMelderDeactivatedBody: nil, appointmentPhoneNumber: nil, featureFlags: [], shareKeyURL: nil, coronaTestURL: nil)))
    }

    func getRiskCalculationParameters(identifier: String, completion: @escaping (Result<RiskCalculationParameters, NetworkError>) -> ()) {
        completion(.failure(.invalidRequest))
    }

    func getExposureKeySet(identifier: String, completion: @escaping (Result<URL, NetworkError>) -> ()) {
        completion(.failure(.invalidRequest))
    }

    // MARK: Enrollment

    func postRegister(request: RegisterRequest, completion: @escaping (Result<LabInformation, NetworkError>) -> ()) {
        completion(.failure(.invalidRequest))
    }

    func postKeys(request: PostKeysRequest, signature: String, completion: @escaping (NetworkError?) -> ()) {
        completion(.invalidRequest)
    }

    func postStopKeys(request: PostKeysRequest, signature: String, completion: @escaping (NetworkError?) -> ()) {
        completion(.invalidRequest)
    }
}
