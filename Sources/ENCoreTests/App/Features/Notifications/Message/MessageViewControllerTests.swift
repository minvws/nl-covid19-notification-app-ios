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
    private var listner: MessageListenerMock!
    private var storageController: StorageControllingMock!
    private var messageManager: MessageManager!
    private var exposureDate: Date!

    override func setUp() {
        super.setUp()

        listner = MessageListenerMock()
        storageController = StorageControllingMock()
        messageManager = MessageManager(storageController: storageController, theme: self.theme)

        recordSnapshots = false

        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        exposureDate = Date(timeIntervalSince1970: 1593290000) // 27/06/20 20:33

        viewController = MessageViewController(listener: listner,
                                               theme: theme,
                                               exposureDate: exposureDate,
                                               messageManager: messageManager)
    }

    // MARK: - Tests

    func testSnapshotMessageViewController() {
        snapshots(matching: viewController)
    }

    func testPresentationControllerDidDismissCallsListener() {
        listner.messageWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listner.messageWantsDismissalCallCount, 1)
    }
}
