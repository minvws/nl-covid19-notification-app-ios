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

final class CallGGDControllerTests: TestCase {
    private var viewController: CallGGDViewController!
    private let listener = CallGGDListenerMock()
    private let interfaceOrientationStream = InterfaceOrientationStreamingMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false
        interfaceOrientationStream.isLandscape = BehaviorSubject(value: false)

        viewController = CallGGDViewController(listener: listener,
                                               theme: theme,
                                               interfaceOrientationStream: interfaceOrientationStream)
    }

    // MARK: - Tests

    func testSnapshotCallGGDViewController() {
        snapshots(matching: viewController)
    }

    func testPresentationControllerDidDismissCallsListener() {
        listener.callGGDWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listener.callGGDWantsDismissalCallCount, 1)
    }
}
