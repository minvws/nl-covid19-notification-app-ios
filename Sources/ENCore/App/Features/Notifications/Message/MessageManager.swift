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
    func getLocalizedTreatmentPerspective(withExposureDate exposureDate: Date) -> LocalizedTreatmentPerspective
}

final class MessageManager: MessageManaging, Logging {

    enum TreatmentPerspectivePlaceholder: String {
        case exposureDate = "{ExposureDate}"
        case exposureDaysAgo = "{ExposureDaysAgo}"
        case stayHomeUntilDate = "{StayHomeUntilDate}"
    }

    // MARK: - Init

    init(storageController: StorageControlling, theme: Theme) {
        self.storageController = storageController
        self.theme = theme
    }

    func getLocalizedTreatmentPerspective(withExposureDate exposureDate: Date) -> LocalizedTreatmentPerspective {

        let treatmentPerspective = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.treatmentPerspective) ??
            TreatmentPerspective.fallbackMessage

        let resource = treatmentPerspective.resources[.currentLanguageIdentifier]
        let fallbackResource = treatmentPerspective.resources["en"]

        guard resource != nil || fallbackResource != nil else {
            return .emptyMessage
        }

        let paragraphs = paragraphsFromLayout(
            treatmentPerspective.guidance.layout,
            exposureDate: exposureDate,
            quarantineDays: treatmentPerspective.guidance.quarantineDays,
            withLanguageResource: resource,
            languageResourceFallback: fallbackResource
        )

        return LocalizedTreatmentPerspective(paragraphs: paragraphs,
                                             quarantineDays: treatmentPerspective.guidance.quarantineDays)
    }

    // MARK: - Private

    private func paragraphsFromLayout(
        _ layoutElements: [TreatmentPerspective.LayoutElement],
        exposureDate: Date,
        quarantineDays: Int,
        withLanguageResource resource: [String: String]?,
        languageResourceFallback fallback: [String: String]?
    ) -> [LocalizedTreatmentPerspective.Paragraph] {

        return layoutElements.compactMap {

            guard let title = $0.title, let resourceTitle = resource?[title] ?? fallback?[title],
                let body = $0.body, let resourceBody = resource?[body] ?? fallback?[body],
                let type = LocalizedTreatmentPerspective.Paragraph.ParagraphType(rawValue: $0.type) else {
                return nil
            }

            let paragraphTitle = replacePlaceholders(inString: NSAttributedString(string: resourceTitle),
                                                     withExposureDate: exposureDate,
                                                     quarantineDays: quarantineDays)

            var paragraphBody = replacePlaceholders(inString: NSAttributedString(string: resourceBody),
                                                    withExposureDate: exposureDate,
                                                    quarantineDays: quarantineDays)
            paragraphBody = .htmlWithBulletList(text: paragraphBody.string,
                                                font: theme.fonts.body,
                                                textColor: theme.colors.gray,
                                                theme: theme)

            return LocalizedTreatmentPerspective.Paragraph(
                title: paragraphTitle,
                body: paragraphBody,
                type: type
            )
        }
    }

    private func replacePlaceholders(inString attributedString: NSAttributedString, withExposureDate exposureDate: Date, quarantineDays: Int) -> NSAttributedString {

        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        var text = mutableAttributedString.string

        text = formatExposureDate(&text, withExposureDate: exposureDate)
        text = formatStayHomeUntilDate(&text, withExposureDate: exposureDate, andQuarantineDays: quarantineDays)

        mutableAttributedString.mutableString.setString(text)

        return NSAttributedString(attributedString: mutableAttributedString)
    }

    private func formatExposureDate(_ text: inout String, withExposureDate exposureDate: Date) -> String {

        let now = currentDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let dateString = dateFormatter.string(from: exposureDate)
        let days = now.days(sinceDate: exposureDate) ?? 0

        text = text.replacingOccurrences(of: TreatmentPerspectivePlaceholder.exposureDate.rawValue,
                                         with: dateString)
        text = text.replacingOccurrences(of: TreatmentPerspectivePlaceholder.exposureDaysAgo.rawValue,
                                         with: String.statusNotifiedDaysAgo(days: days))

        return text
    }

    private func formatStayHomeUntilDate(_ text: inout String, withExposureDate exposureDate: Date, andQuarantineDays quarantineDays: Int) -> String {

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        var addingDaysComponents = DateComponents()
        addingDaysComponents.day = quarantineDays

        guard let daysAfterExposure = Calendar.current.date(byAdding: addingDaysComponents, to: exposureDate) else {
            return text
        }

        text = text.replacingOccurrences(of: TreatmentPerspectivePlaceholder.stayHomeUntilDate.rawValue,
                                         with: dateFormatter.string(from: daysAfterExposure))

        return text
    }

    private let storageController: StorageControlling
    private let theme: Theme
}
