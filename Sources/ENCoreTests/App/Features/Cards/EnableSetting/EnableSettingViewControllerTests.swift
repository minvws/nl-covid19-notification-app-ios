/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import Foundation
import XCTest

final class EnableSettingViewControllerTests: TestCase {
    private var viewController: EnableSettingViewController!
    private let listener = EnableSettingListenerMock()
    private var exposureStateStream = ExposureStateStreamingMock()
    private var environmentController = EnvironmentControllingMock()

    override func setUp() {
        super.setUp()

        viewController = EnableSettingViewController(listener: listener,
                                                     theme: theme,
                                                     setting: .enableBluetooth,
                                                     exposureStateStream: exposureStateStream,
                                                     environmentController: environmentController)
    }

    func test_presentationControllerDidDismiss_callsListener() {
        var shouldDismissViewController: Bool!

        listener.enableSettingRequestsDismissHandler = { shouldDismissViewController = $0 }

        XCTAssertEqual(listener.enableSettingRequestsDismissCallCount, 0)

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: UIViewController(), presenting: nil))

        XCTAssertEqual(listener.enableSettingRequestsDismissCallCount, 1)
        XCTAssertEqual(shouldDismissViewController, false)
    }

    func test_enablingBluetoothShouldDimissScreen() {

        XCTAssertEqual(listener.enableSettingRequestsDismissCallCount, 0)

        exposureStateStream.exposureState = Just(ExposureState(notifiedState: .notNotified, activeState: .inactive(.bluetoothOff))).eraseToAnyPublisher()

        viewController.viewDidLoad()

        exposureStateStream.exposureState = Just(ExposureState(notifiedState: .notNotified, activeState: .active)).eraseToAnyPublisher()

        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        XCTAssertEqual(listener.enableSettingRequestsDismissCallCount, 1)
    }
}
