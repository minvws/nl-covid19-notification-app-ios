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

final class RequestTestViewControllerTests: TestCase {
    private var viewController: RequestTestViewController!
    private let listener = RequestTestListenerMock()
    private var interfaceOrientationStream = InterfaceOrientationStreamingMock()
    private var exposureStateStream = MutableExposureStateStreamingMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        interfaceOrientationStream.isLandscape = Just(false).eraseToAnyPublisher()

        viewController = RequestTestViewController(listener: listener,
                                                   theme: theme,
                                                   interfaceOrientationStream: interfaceOrientationStream,
                                                   exposureStateStream: exposureStateStream)
    }

    // MARK: - Tests

    func testSnapshotRequestTestViewController() {
        snapshots(matching: viewController)
    }

    // Tests the screen with arabic (RTL) language to ensure proper formatting of phone numbers in text and buttons
    // Be aware that although we override the RTL setting. Some text in this screen will still appear left-to-right because
    // the iOS labels listen to the actual device RTL setting and not our custom setting
    func testSnapshotRequestTestViewControllerRTL() {
        LocalizationOverrides.overriddenLocalization = "ar"
        LocalizationOverrides.overriddenIsRTL = true
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "ar"

        snapshots(matching: viewController)

        LocalizationOverrides.overriddenLocalization = nil
        LocalizationOverrides.overriddenIsRTL = nil
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = nil
    }

    func testPresentationControllerDidDismissCallsListener() {
        listener.requestTestWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listener.requestTestWantsDismissalCallCount, 1)
    }
}
