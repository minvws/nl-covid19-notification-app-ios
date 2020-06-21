/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

final class UploadDiagnosisKeysDataOperation: ExposureDataOperation {
    init(networkController: NetworkControlling,
         diagnosisKeys: [DiagnosisKey],
         labConfirmationKey: LabConfirmationKey) {
        self.networkController = networkController
        self.diagnosisKeys = diagnosisKeys
        self.labConfirmationKey = labConfirmationKey
    }

    func execute() -> AnyPublisher<(), ExposureDataError> {
        return networkController
            .postKeys(keys: diagnosisKeys, labConfirmationKey: labConfirmationKey)
            .mapError { (error: NetworkError) -> ExposureDataError in error.asExposureDataError }
            .eraseToAnyPublisher()
    }

    private let networkController: NetworkControlling
    private let diagnosisKeys: [DiagnosisKey]
    private let labConfirmationKey: LabConfirmationKey
}
