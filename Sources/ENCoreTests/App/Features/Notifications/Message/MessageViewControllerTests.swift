/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
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
    private let mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()

    override func setUp() {
        super.setUp()

        listener = MessageListenerMock()
        storageController = StorageControllingMock()
        messageManager = MessageManagingMock()

        recordSnapshots = false
        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        exposureDate = Date(timeIntervalSince1970: 1593290000) // 27/06/20 20:33

        mockInterfaceOrientationStream.isLandscape = Just(false).eraseToAnyPublisher()
    }

    // MARK: - Tests

    func testSnapshotMessageViewController_withList() {
        messageManager.getLocalizedTreatmentPerspectiveHandler = { date in
            self.fakeMessageWithList
        }

        viewController = MessageViewController(listener: listener, theme: theme, exposureDate: exposureDate, interfaceOrientationStream: mockInterfaceOrientationStream, messageManager: messageManager)

        snapshots(matching: viewController)
    }

    func testSnapshotMessageViewController_withoutList() {
        messageManager.getLocalizedTreatmentPerspectiveHandler = { date in
            self.fakeMessageWithoutList
        }

        viewController = MessageViewController(listener: listener, theme: theme, exposureDate: exposureDate, interfaceOrientationStream: mockInterfaceOrientationStream, messageManager: messageManager)

        snapshots(matching: viewController)
    }

    func testSnapshotMessageViewController_rtl() {
        // TODO: create RTL snapshot here
        XCTFail()
    }

    func testPresentationControllerDidDismissCallsListener() {
        messageManager.getLocalizedTreatmentPerspectiveHandler = { date in
            self.fakeMessageWithList
        }

        viewController = MessageViewController(listener: listener, theme: theme, exposureDate: exposureDate, interfaceOrientationStream: mockInterfaceOrientationStream, messageManager: messageManager)

        listener.messageWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listener.messageWantsDismissalCallCount, 1)
    }

    // MARK: - Private

    private lazy var fakeMessageWithList: LocalizedTreatmentPerspective = {
        LocalizedTreatmentPerspective(paragraphs: [
            .init(title: NSAttributedString(string: "Paragraph Title"),
                  body: .htmlWithBulletList(text: "Intro text.\n\nSecond intro.\n\n<ul><li>List Item 1</li><li>List Item 2</li></ul>\nText below list", font: self.theme.fonts.body, textColor: self.theme.colors.gray, theme: self.theme),
                  type: .paragraph)
        ], quarantineDays: 10)
    }()

    private lazy var fakeMessageWithoutList: LocalizedTreatmentPerspective = {
        LocalizedTreatmentPerspective(paragraphs: [
            .init(title: NSAttributedString(string: "Paragraph Title"),
                  body: .htmlWithBulletList(text: "Some paragraph of text that is not followed by a list\n\nSome other paragraph of text", font: self.theme.fonts.body, textColor: self.theme.colors.gray, theme: self.theme),
                  type: .paragraph)
        ], quarantineDays: 10)
    }()
}
