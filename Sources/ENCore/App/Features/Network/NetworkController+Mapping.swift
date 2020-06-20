/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension LabInformation {
    var asLabConfirmationKey: LabConfirmationKey? {
        guard
            let bucketIdentifier = Data(base64Encoded: bucketId) else {
            return nil
        }

        return LabConfirmationKey(identifier: labConfirmationId,
                                  bucketIdentifier: bucketIdentifier,
                                  confirmationKey: confirmationKey,
                                  validUntil: Date(timeIntervalSinceNow: TimeInterval(validity)))
    }
}

extension DiagnosisKey {
    var asTemporaryKey: TemporaryKey {
        return TemporaryKey(keyData: keyData.base64EncodedString(),
                            rollingStartNumber: Int(rollingStartNumber),
                            rollingPeriod: Int(rollingPeriod))
    }
}
