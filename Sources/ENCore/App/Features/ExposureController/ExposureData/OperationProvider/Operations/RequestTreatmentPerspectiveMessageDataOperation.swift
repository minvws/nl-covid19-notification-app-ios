/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation

enum TreatmentPerspective {

    struct Message: Codable {
        let paragraphs: [Paragraph]
        let quarantineDays: Int
    }

    struct DynamicNotification: Codable {
        let guidance: Guidance
    }

    struct Guidance: Codable {
        let quarantineDays: Int
        let layout: [LayoutElement]
    }

    struct LayoutElement: Codable {
        let title, body, type: String
    }

    enum Keys: String {
        case resources
    }

    enum ParagraphType: String {
        case paragraph
        case unknown
    }

    final class Paragraph: Codable {

        var title: NSAttributedString
        var body: NSAttributedString
        let type: ParagraphType.RawValue

        enum CodingKeys: String, CodingKey {
            case title, body, type
        }

        init(title: NSAttributedString, body: NSAttributedString, type: ParagraphType) {
            self.title = title
            self.body = body
            self.type = type.rawValue
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let title = try container.decodeIfPresent(Data.self, forKey: .title) {
                self.title = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: title) ?? NSAttributedString()
            } else {
                self.title = NSAttributedString()
            }
            if let body = try container.decodeIfPresent(Data.self, forKey: .body) {
                self.body = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: body) ?? NSAttributedString()
            } else {
                self.body = NSAttributedString()
            }
            self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(NSKeyedArchiver.archivedData(withRootObject: title, requiringSecureCoding: false), forKey: .title)
            try container.encode(NSKeyedArchiver.archivedData(withRootObject: body, requiringSecureCoding: false), forKey: .body)
            try container.encode(type, forKey: .type)
        }
    }

    enum MessageType: CodingKey {
        case paragraph, notificationCode
    }

    static var emptyMessage: Message {
        return Message(paragraphs: [Paragraph(title: NSAttributedString(string: ""),
                                              body: NSAttributedString(string: ""),
                                              type: ParagraphType.unknown)],
        quarantineDays: 10)
    }
}

final class RequestTreatmentPerspectiveMessageDataOperation: ExposureDataOperation, Logging {
    typealias Result = TreatmentPerspective.Message

    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<TreatmentPerspective.Message, ExposureDataError> {

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

        return Just(retrieveFallbackTreatmentPerspectiveMessage())
            .setFailureType(to: ExposureDataError.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func retrieveStoredTreatmentPerspectiveMessage() -> TreatmentPerspective.Message? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.treatmentPerspectiveMessage)
    }

    private func retrieveFallbackTreatmentPerspectiveMessage() -> TreatmentPerspective.Message {

        guard let path = Bundle(for: RequestTreatmentPerspectiveMessageDataOperation.self).path(forResource: "DefaultDynamicNotification", ofType: "json") else {
            self.logError("DefaultDynamicNotification.json not found")
            return TreatmentPerspective.emptyMessage
        }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path),
                                   options: .mappedIfSafe) else {
            self.logError("Could not transform DefaultDynamicNotification.json into data")
            return TreatmentPerspective.emptyMessage
        }

        var paragraphs = [TreatmentPerspective.Paragraph]()

        guard let dynamicNotification = try? JSONDecoder().decode(TreatmentPerspective.DynamicNotification.self, from: data) else {
            self.logError("Could not decode dynamicNotification")
            return TreatmentPerspective.emptyMessage
        }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            self.logError("Could not serialize JSON")
            return TreatmentPerspective.emptyMessage
        }

        guard let resources = json[TreatmentPerspective.Keys.resources.rawValue] as? [String: Any] else {
            self.logError("Could not fromat resources")
            return TreatmentPerspective.emptyMessage
        }

        guard let resource = resources[.currentLanguageIdentifier] as? [String: String] else {
            self.logError("Could not find language")
            return TreatmentPerspective.emptyMessage
        }

        dynamicNotification.guidance.layout.forEach {

            paragraphs.append(
                TreatmentPerspective.Paragraph(title: NSAttributedString(string: resource[$0.title] ?? ""),
                                               body: NSAttributedString(string: resource[$0.body] ?? ""),
                                               type: TreatmentPerspective.ParagraphType(rawValue: $0.type) ?? .unknown)
            )
        }

        return TreatmentPerspective.Message(paragraphs: paragraphs,
                                            quarantineDays: dynamicNotification.guidance.quarantineDays)
    }

    private func retrieveStoredManifest() -> ApplicationManifest? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appManifest)
    }

    private func silentStore(treatmentPerspectiveMessage: TreatmentPerspective.Message) {
        self.storageController.store(object: treatmentPerspectiveMessage,
                                     identifiedBy: ExposureDataStorageKey.treatmentPerspectiveMessage,
                                     completion: { error in
                                         if let error = error {
                                             self.logError(error.localizedDescription)
                                         }
            })
    }

    private func store(treatmentPerspectiveMessage: TreatmentPerspective.Message) -> AnyPublisher<TreatmentPerspective.Message, ExposureDataError> {
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
