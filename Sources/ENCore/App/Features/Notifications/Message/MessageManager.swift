/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import UIKit

/// @mockable
protocol MessageManaging: AnyObject {
    func getTreatmentPerspectiveMessage() -> TreatmentPerspectiveMessage
}

final class MessageManager: MessageManaging, Logging {

    // MARK: - Init

    init(storageController: StorageControlling, theme: Theme) {
        self.storageController = storageController
        self.theme = theme
    }

    func getTreatmentPerspectiveMessage() -> TreatmentPerspectiveMessage {

        guard let treatmentPerspectiveMessage = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.treatmentPerspectiveMessage) else {
            self.logError("No Treatment Perspective Message found, returning empty one")
            return emptyTreatmentPerspectiveMessage
        }

        treatmentPerspectiveMessage.paragraphs.forEach {
            $0.body = .htmlWithBulletList(text: $0.body.string,
                                          font: theme.fonts.body,
                                          textColor: .black, theme: theme)
        }

        return treatmentPerspectiveMessage
    }

    // MARK: - Private

    private let storageController: StorageControlling
    private let theme: Theme
}
