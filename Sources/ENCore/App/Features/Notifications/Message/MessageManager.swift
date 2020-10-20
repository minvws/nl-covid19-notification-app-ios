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
    func getTreatmentPerspectiveMessage(withExposureDate exposureDate: Date) -> TreatmentPerspective.Message
}

final class MessageManager: MessageManaging, Logging {

    enum TreatmentPerspectiveMessagePlaceholder: String {
        case exposureDate = "{ExposureDate}"
        case exposureDaysAgo = "{ExposureDaysAgo}"
        case stayHomeUntilDate = "{StayHomeUntilDate}"
    }

    // MARK: - Init

    init(storageController: StorageControlling, theme: Theme) {
        self.storageController = storageController
        self.theme = theme
    }

    func getTreatmentPerspectiveMessage(withExposureDate exposureDate: Date) -> TreatmentPerspective.Message {

        let treatmentPerspectiveMessage = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.treatmentPerspectiveMessage) ??
            TreatmentPerspective.fallbackMessage

        treatmentPerspectiveMessage.paragraphs.forEach {

            $0.title = replacePlaceholders($0.title,
                                           withExposureDate: exposureDate,
                                           quarantineDays: treatmentPerspectiveMessage.quarantineDays)

            $0.body = replacePlaceholders($0.body,
                                          withExposureDate: exposureDate,
                                          quarantineDays: treatmentPerspectiveMessage.quarantineDays)

            $0.body = .htmlWithBulletList(text: $0.body.string,
                                          font: theme.fonts.body,
                                          textColor: .black, theme: theme)
        }

        return treatmentPerspectiveMessage
    }

    // MARK: - Private

    private func replacePlaceholders(_ attributedString: NSAttributedString, withExposureDate exposureDate: Date, quarantineDays: Int) -> NSAttributedString {

        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        var text = mutableAttributedString.string

        text = formatExposureDate(&text, withExposureDate: exposureDate)
        text = formatTenDaysAfterExposure(&text, withExposureDate: exposureDate, andQuarantineDays: quarantineDays)

        mutableAttributedString.mutableString.setString(text)

        return NSAttributedString(attributedString: mutableAttributedString)
    }

    private func formatExposureDate(_ text: inout String, withExposureDate exposureDate: Date) -> String {

        let now = currentDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let dateString = dateFormatter.string(from: exposureDate)
        let days = now.days(sinceDate: exposureDate) ?? 0

        text = text.replacingOccurrences(of: TreatmentPerspectiveMessagePlaceholder.exposureDate.rawValue,
                                         with: dateString)
        text = text.replacingOccurrences(of: TreatmentPerspectiveMessagePlaceholder.exposureDaysAgo.rawValue,
                                         with: String.statusNotifiedDaysAgo(days: days))

        return text
    }

    private func formatTenDaysAfterExposure(_ text: inout String, withExposureDate exposureDate: Date, andQuarantineDays quarantineDays: Int) -> String {

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let days: TimeInterval = TimeInterval(60 * 60 * 24 * quarantineDays)
        let daysAfterExposure = exposureDate.advanced(by: days)

        text = text.replacingOccurrences(of: TreatmentPerspectiveMessagePlaceholder.stayHomeUntilDate.rawValue,
                                         with: dateFormatter.string(from: daysAfterExposure))

        return text
    }

    private let storageController: StorageControlling
    private let theme: Theme
}
