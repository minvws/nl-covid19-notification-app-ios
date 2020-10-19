/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation

struct TreatmentPerspectiveMessage: Codable {
    let paragraphs: [Paragraph]
}

struct DynamicNotification: Codable {
    let guidance: Guidance
}

struct Guidance: Codable {
    let quarantineDays: Int
    let layouts: [Layout]

    enum CodingKeys: String, CodingKey {
        case quarantineDays
        case layouts = "layout"
    }
}

struct Layout: Codable {
    let title, body, type: String
}

enum Keys: String {
    case resources
}

enum ParagraphType: String {
    case paragraph
    case unknown
}

class Paragraph: Codable {

    let title: String
    var body: NSAttributedString
    let type: ParagraphType.RawValue

    enum CodingKeys: String, CodingKey {
        case title, body, type
    }

    init(title: String, body: NSAttributedString, type: ParagraphType) {
        self.title = title
        self.body = body
        self.type = type.rawValue
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        if let body = try container.decodeIfPresent(Data.self, forKey: .body) {
            self.body = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: body) ?? NSAttributedString()
        } else {
            self.body = NSAttributedString()
        }
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(NSKeyedArchiver.archivedData(withRootObject: body, requiringSecureCoding: false), forKey: .body)
        try container.encode(type, forKey: .type)
    }
}

enum MessageType: CodingKey {
    case paragraph, notificationCode
}

let emptyTreatmentPerspectiveMessage = TreatmentPerspectiveMessage(paragraphs: [Paragraph(title: "",
                                                                                          body: NSAttributedString(string: ""),
                                                                                          type: ParagraphType.unknown)])

final class RequestTreatmentPerspectiveMessageDataOperation: ExposureDataOperation, Logging {
    typealias Result = TreatmentPerspectiveMessage

    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<TreatmentPerspectiveMessage, ExposureDataError> {

        if let manifest = retrieveStoredManifest(),
            let identifier = manifest.resourceBundleId {

            return networkController
                .treatmentPerspectiveMessage(identifier: identifier)
                .mapError { $0.asExposureDataError }
                .flatMap(store(treatmentPerspectiveMessage:))
                .share()
                .eraseToAnyPublisher()
        }

        if let storedTreatmentPerspectiveMessage = retrieveStoredTreatmentPerspectiveMessage() {
            return Just(storedTreatmentPerspectiveMessage)
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        let fallback = retrieveFallbackTreatmentPerspectiveMessage()
        self.silentStore(treatmentPerspectiveMessage: fallback)

        return Just(fallback)
            .setFailureType(to: ExposureDataError.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func retrieveStoredTreatmentPerspectiveMessage() -> TreatmentPerspectiveMessage? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.treatmentPerspectiveMessage)
    }

    private func retrieveFallbackTreatmentPerspectiveMessage() -> TreatmentPerspectiveMessage {

        guard let path = Bundle(for: RequestTreatmentPerspectiveMessageDataOperation.self).path(forResource: "DefaultDynamicNotification", ofType: "json") else {
            self.logError("DefaultDynamicNotification.json not found")
            return emptyTreatmentPerspectiveMessage
        }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path),
                                   options: .mappedIfSafe) else {
            self.logError("Could not transform DefaultDynamicNotification.json into data")
            return emptyTreatmentPerspectiveMessage
        }

        var paragraphs = [Paragraph]()

        guard let dynamicNotification = try? JSONDecoder().decode(DynamicNotification.self, from: data) else {
            self.logError("Could not decode dynamicNotification")
            return emptyTreatmentPerspectiveMessage
        }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            self.logError("Could not serialize JSON")
            return emptyTreatmentPerspectiveMessage
        }

        guard let resources = json[Keys.resources.rawValue] as? [String: Any] else {
            self.logError("Could not fromat resources")
            return emptyTreatmentPerspectiveMessage
        }

        guard let resource = resources[.currentLanguageIdentifier] as? [String: String] else {
            self.logError("Could not find language")
            return emptyTreatmentPerspectiveMessage
        }

        dynamicNotification.guidance.layouts.forEach {

            paragraphs.append(
                Paragraph(title: resource[$0.title] ?? "",
                          body: NSAttributedString(string: resource[$0.body] ?? ""),
                          type: ParagraphType(rawValue: $0.type) ?? .unknown)
            )
        }

        return TreatmentPerspectiveMessage(paragraphs: paragraphs)
    }

    private func retrieveStoredManifest() -> ApplicationManifest? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appManifest)
    }

    private func silentStore(treatmentPerspectiveMessage: TreatmentPerspectiveMessage) {
        self.storageController.store(object: treatmentPerspectiveMessage,
                                     identifiedBy: ExposureDataStorageKey.treatmentPerspectiveMessage,
                                     completion: { error in
                                         if let error = error {
                                             self.logError(error.localizedDescription)
                                         }
            })
    }

    private func store(treatmentPerspectiveMessage: TreatmentPerspectiveMessage) -> AnyPublisher<TreatmentPerspectiveMessage, ExposureDataError> {
        return Future { promise in
            self.storageController.store(object: treatmentPerspectiveMessage,
                                         identifiedBy: ExposureDataStorageKey.treatmentPerspectiveMessage,
                                         completion: { _ in
                                             promise(.success(treatmentPerspectiveMessage))
                })
        }
        .share()
        .eraseToAnyPublisher()
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}
