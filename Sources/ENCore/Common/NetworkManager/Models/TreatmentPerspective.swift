/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct TreatmentPerspective: Codable {
    let resources: [String: [String: String]]
    let guidance: Guidance

    struct Guidance: Codable {
        let quarantineDays: Int
        let layout: [LayoutElement]
    }

    struct LayoutElement: Codable {
        let title: String?
        let body: String?
        let type: String
    }
}

extension TreatmentPerspective {
    static var fallbackMessage: TreatmentPerspective {
        guard let path = Bundle(for: RequestTreatmentPerspectiveDataOperation.self).path(forResource: "DefaultTreatmentPerspective", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let treatmentPerspective = try? JSONDecoder().decode(TreatmentPerspective.self, from: data) else {
            return .emptyMessage
        }

        return treatmentPerspective
    }

    static var emptyMessage: TreatmentPerspective {
        return TreatmentPerspective(resources: [:], guidance: Guidance(quarantineDays: 10, layout: []))
    }
}

struct LocalizedTreatmentPerspective {

    var paragraphs: [Paragraph]
    let quarantineDays: Int

    struct Paragraph {
        var title: NSAttributedString
        var body: NSAttributedString
        let type: ParagraphType

        enum ParagraphType: String {
            case paragraph
            case unknown
        }
    }
}

extension LocalizedTreatmentPerspective {
    static var emptyMessage: LocalizedTreatmentPerspective {
        return LocalizedTreatmentPerspective(paragraphs: [], quarantineDays: 10)
    }
}
