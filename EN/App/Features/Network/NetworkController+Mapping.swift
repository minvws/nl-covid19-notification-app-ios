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
            let bucketIdentifier = Data(base64Encoded: bucketId),
            let confirmationKey = Data(base64Encoded: confirmationKey) else {
            return nil
        }

        return LabConfirmationKey(identifier: labConfirmationId,
                                  bucketIdentifier: bucketIdentifier,
                                  confirmationKey: confirmationKey,
                                  validUntil: Date(timeIntervalSinceNow: TimeInterval(validity)))
    }
}
