/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import SnapshotTesting
import XCTest

final class MessageViewControllerTests: TestCase {
    private var viewController: MessageViewController!
    private let listern = MessageListenerMock()
    private var messageManager: MessageManagingMock!

    override func setUp() {
        super.setUp()

        messageManager = MessageManagingMock()

        messageManager.getTreatmentPerspectiveMessageHandler = { _ in
            return self.retrieveFallbackTreatmentPerspectiveMessage()
        }

        recordSnapshots = false

        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28

        viewController = MessageViewController(listener: listern,
                                               theme: theme,
                                               exposureDate: Date(timeIntervalSince1970: 1593290000), // 27/06/20 20:33
                                               messageManager: messageManager)
    }

    // MARK: - Tests

    func testSnapshotMessageViewController() {
        snapshots(matching: viewController)
    }

    func testPresentationControllerDidDismissCallsListener() {
        listern.messageWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listern.messageWantsDismissalCallCount, 1)
    }

    private func retrieveFallbackTreatmentPerspectiveMessage() -> TreatmentPerspective.Message {

        guard let path = Bundle(for: RequestTreatmentPerspectiveMessageDataOperation.self).path(forResource: "DefaultDynamicNotification", ofType: "json") else {
            return TreatmentPerspective.emptyMessage
        }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path),
                                   options: .mappedIfSafe) else {
            return TreatmentPerspective.emptyMessage
        }

        var paragraphs = [TreatmentPerspective.Paragraph]()

        guard let dynamicNotification = try? JSONDecoder().decode(TreatmentPerspective.DynamicNotification.self, from: data) else {
            return TreatmentPerspective.emptyMessage
        }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return TreatmentPerspective.emptyMessage
        }

        guard let resources = json[TreatmentPerspective.Keys.resources.rawValue] as? [String: Any] else {
            return TreatmentPerspective.emptyMessage
        }

        guard let resource = resources[.currentLanguageIdentifier] as? [String: String] else {
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
}
