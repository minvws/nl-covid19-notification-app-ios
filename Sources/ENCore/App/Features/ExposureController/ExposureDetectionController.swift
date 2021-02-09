/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

struct V2ExposureDetectionResult {
    let wasExposed: Bool
}

class ExposureDetectionController {

    private let exposureManager: ExposureManaging

    init(exposureManager: ExposureManaging) {
        self.exposureManager = exposureManager
    }

    func detectExposures(configuration: ExposureConfiguration, diagnosisKeyURLs: [URL]) -> Single<V2ExposureDetectionResult> {

        return getExposureSummary(configuration: configuration, diagnosisKeyURLs: diagnosisKeyURLs)
            .flatMap(getExposureWindows)
            .flatMap(detectExposures)
    }

    private func getExposureSummary(configuration: ExposureConfiguration, diagnosisKeyURLs: [URL]) -> Single<ExposureDetectionSummary?> {

        return .create { (observer) -> Disposable in

            self.exposureManager.detectExposures(configuration: configuration,
                                                 diagnosisKeyURLs: diagnosisKeyURLs) { summaryResult in

                if case let .failure(error) = summaryResult {
                    observer(.failure(error))
                    return
                }

                guard case let .success(summary) = summaryResult else {
                    observer(.success(nil))
                    return
                }

                observer(.success(summary))
            }

            return Disposables.create()
        }
    }

    private func getExposureWindows(fromSummary summary: ExposureDetectionSummary?) -> Single<[ExposureWindow]?> {

        guard let summary = summary else {
            return .just([])
        }

        return .create { (observer) -> Disposable in

            self.exposureManager.getExposureWindows(summary: summary) { windowResult in
                if case let .failure(error) = windowResult {
                    observer(.failure(error))
                    return
                }

                guard case let .success(windows) = windowResult else {
                    observer(.success(nil))
                    return
                }

                observer(.success(windows))
            }

            return Disposables.create()
        }
    }

    private func detectExposures(inWindows exposureWindows: [ExposureWindow]?) -> Single<V2ExposureDetectionResult> {
        return .create { (observer) -> Disposable in

            let wasExposed = exposureWindows?.isEmpty == false

            observer(.success(V2ExposureDetectionResult(wasExposed: wasExposed)))

            return Disposables.create()
        }
    }
}
