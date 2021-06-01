/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import RxSwift
import SnapshotTesting
import XCTest

final class ReceivedNotificationViewControllerTests: TestCase {
    private var viewController: ReceivedNotificationViewController!
    private let listener = ReceivedNotificationListenerMock()
    private var interfaceOrientationStream = InterfaceOrientationStreamingMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        interfaceOrientationStream.isLandscape = BehaviorSubject(value: false)

        let uploadKeys = HelpQuestion(question: .helpFaqUploadKeysTitle, answer: .helpFaqUploadKeysDescription)

        viewController = ReceivedNotificationViewController(listener: listener,
                                                            linkedContent: [AboutEntry.question(uploadKeys)],
                                                            actionButtonTitle: nil,
                                                            theme: theme,
                                                            interfaceOrientationStream: interfaceOrientationStream)
        
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
    }

    // MARK: - Tests

    func testSnapshotReceivedNotificationViewController() {
        snapshots(matching: viewController)
    }

    func testPresentationControllerDidDismissCallsListener() {
        listener.receivedNotificationWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listener.receivedNotificationWantsDismissalCallCount, 1)
    }
}
