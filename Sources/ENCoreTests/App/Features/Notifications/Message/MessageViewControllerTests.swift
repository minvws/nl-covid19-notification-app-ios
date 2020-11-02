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
    private var listener: MessageListenerMock!
    private var storageController: StorageControllingMock!
    private var messageManager: MessageManagingMock!
    private var exposureDate: Date!

    override func setUp() {
        super.setUp()

        listener = MessageListenerMock()
        storageController = StorageControllingMock()
        messageManager = MessageManagingMock()

        messageManager.getLocalizedTreatmentPerspectiveHandler = { date in
            self.fakeMessage
        }

        recordSnapshots = false

        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        exposureDate = Date(timeIntervalSince1970: 1593290000) // 27/06/20 20:33

        viewController = MessageViewController(listener: listener,
                                               theme: theme,
                                               exposureDate: exposureDate,
                                               messageManager: messageManager)
    }

    // MARK: - Tests

    func testSnapshotMessageViewController() {
        snapshots(matching: viewController)
    }

    func testPresentationControllerDidDismissCallsListener() {
        listener.messageWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listener.messageWantsDismissalCallCount, 1)
    }

    // MARK: - Private

    private lazy var fakeMessage: LocalizedTreatmentPerspective = {
        LocalizedTreatmentPerspective(paragraphs: [
            .init(title: NSAttributedString(string: "Paragraph Title"),
                  body: .htmlWithBulletList(text: "<ul><li>List Item 1</li><li>List Item 2</li></ul>Some Other Paragraph", font: self.theme.fonts.body, textColor: self.theme.colors.gray, theme: self.theme),
                  type: .paragraph)
        ], quarantineDays: 10)
    }()
}
