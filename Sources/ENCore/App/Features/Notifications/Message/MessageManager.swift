/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

#if USE_DEVELOPER_MENU || DEBUG
    struct MessageManagerOverrides {
        static var forceBundledTreatmentPerspective = false
    }
#endif

/// @mockable
protocol MessageManaging: AnyObject {
    func getLocalizedTreatmentPerspective(withExposureDate exposureDate: Date) -> LocalizedTreatmentPerspective
}

final class MessageManager: MessageManaging, Logging {

    /// The following placeholders can be used in message text as "{PLACEHOLDERNAME}". They will be replaced with locally-known information by the app.
    enum TreatmentPerspectivePlaceholder: String {
        case exposureDate = "ExposureDate"
        case exposureDaysAgo = "ExposureDaysAgo"
        case exposureDateShort = "ExposureDateShort"
        case stayHomeUntilDate = "StayHomeUntilDate"
    }

    // MARK: - Init

    init(storageController: StorageControlling, theme: Theme) {
        self.storageController = storageController
        self.theme = theme
    }

    func getLocalizedTreatmentPerspective(withExposureDate exposureDate: Date) -> LocalizedTreatmentPerspective {

        var treatmentPerspective: TreatmentPerspective = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.treatmentPerspective) ?? .fallbackMessage

        #if USE_DEVELOPER_MENU || DEBUG
            if MessageManagerOverrides.forceBundledTreatmentPerspective {
                treatmentPerspective = .fallbackMessage
            }
        #endif

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

            let htmlBody = replacePlaceholders(inString: NSAttributedString(string: resourceBody),
                                               withExposureDate: exposureDate,
                                               quarantineDays: quarantineDays)

            let paragraphBody = NSAttributedString.htmlWithBulletList(text: htmlBody.string,
                                                                      font: theme.fonts.body,
                                                                      textColor: theme.colors.gray,
                                                                      theme: theme,
                                                                      textAlignment: Localization.isRTL ? .right : .left)

            return LocalizedTreatmentPerspective.Paragraph(
                title: paragraphTitle.string,
                body: paragraphBody,
                type: type
            )
        }
    }

    private func replacePlaceholders(inString attributedString: NSAttributedString, withExposureDate exposureDate: Date, quarantineDays: Int) -> NSAttributedString {

        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        let originalText = mutableAttributedString.string
        var modifiedText = mutableAttributedString.string

        // Find all placeholders in the string
        let fullRange = NSRange(location: 0, length: originalText.utf16.count)
        let regex = try! NSRegularExpression(pattern: "\\{[a-zA-Z]+[+]?[0-9]*\\}")

        regex
            .matches(in: originalText, options: [], range: fullRange)
            .compactMap { Range($0.range, in: originalText) }
            .forEach { placeholderRange in

                let placeholder = String(originalText[placeholderRange])
                let trimmedPlaceholder = placeholder.trimmingCharacters(in: CharacterSet(charactersIn: "{}"))

                // Placeholders can contain a number like so: {SomeDatePlaceHolder+3}
                // in which case that number is the number of days that should be added to the date.
                // Split the placeholder on the plus-sign to see if this is the case
                let placeholderComponents = trimmedPlaceholder.components(separatedBy: CharacterSet(charactersIn: "+"))

                guard let knownPlaceholder = TreatmentPerspectivePlaceholder(rawValue: placeholderComponents[0]) else {
                    return
                }

                var daysAdded = 0
                if let dayComponent = placeholderComponents[safe: 1] {
                    daysAdded = Int(dayComponent) ?? 0
                }

                var replacementString = placeholder

                switch knownPlaceholder {
                case .exposureDate:
                    replacementString = formatDate(exposureDate, fromTemplate: "EEEEdMMMM", addingDays: daysAdded)
                case .exposureDateShort:
                    replacementString = formatDate(exposureDate, fromTemplate: "dMMMM", addingDays: daysAdded)
                case .exposureDaysAgo:
                    replacementString = statusNotifiedDaysAgo(withExposureDate: exposureDate)
                case .stayHomeUntilDate:
                    replacementString = formatStayHomeUntilDate(withExposureDate: exposureDate, andQuarantineDays: quarantineDays) ?? replacementString
                }

                modifiedText = modifiedText.replacingOccurrences(of: placeholder, with: replacementString)
            }

        mutableAttributedString.mutableString.setString(modifiedText)

        return NSAttributedString(attributedString: mutableAttributedString)
    }

    private func formatDate(_ date: Date, fromTemplate template: String, addingDays daysAdded: Int?) -> String {

        var dateComponent = DateComponents()
        dateComponent.day = daysAdded

        let dateToFormat = Calendar.current.date(byAdding: dateComponent, to: date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: Locale.current)

        return dateFormatter.string(from: dateToFormat ?? date)
    }

    private func statusNotifiedDaysAgo(withExposureDate exposureDate: Date) -> String {
        let now = currentDate()
        let days = now.days(sinceDate: exposureDate) ?? 0
        return String.statusNotifiedDaysAgo(days: days)
    }

    private func formatStayHomeUntilDate(withExposureDate exposureDate: Date, andQuarantineDays quarantineDays: Int) -> String? {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEEddMMMM", options: 0, locale: Locale.current)

        var addingDaysComponents = DateComponents()
        addingDaysComponents.day = quarantineDays

        guard let daysAfterExposure = Calendar.current.date(byAdding: addingDaysComponents, to: exposureDate) else {
            return nil
        }

        return dateFormatter.string(from: daysAfterExposure)
    }

    private let storageController: StorageControlling
    private let theme: Theme
}
