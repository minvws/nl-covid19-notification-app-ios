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
    private let listener = MessageListenerMock()
    private let mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false
        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28

        mockInterfaceOrientationStream.isLandscape = Just(false).eraseToAnyPublisher()

        viewController = MessageViewController(listener: listener,
                                               theme: theme,
                                               exposureDate: Date(timeIntervalSince1970: 1593290000), // 27/06/20 20:33
                                               interfaceOrientationStream: mockInterfaceOrientationStream)
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
}
