/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import Foundation
import SnapshotTesting
import XCTest

final class RequestTestViewControllerTests: TestCase {
    private var viewController: RequestTestViewController!
    private let listener = RequestTestListenerMock()
    private var deviceOrientationStream = DeviceOrientationStreamingMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        deviceOrientationStream.isLandscape = Just(false).eraseToAnyPublisher()

        viewController = RequestTestViewController(listener: listener,
                                                   theme: theme,
                                                   deviceOrientationStream: deviceOrientationStream)
    }

    // MARK: - Tests

    func testSnapshotRequestTestViewController() {
        snapshots(matching: viewController)
    }

    func testPresentationControllerDidDismissCallsListener() {
        listener.requestTestWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listener.requestTestWantsDismissalCallCount, 1)
    }
}
