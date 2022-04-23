/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import RxSwift
import SnapshotTesting
import XCTest

final class ShareKeyViaPhoneViewControllerSnapshotTests: TestCase {
    private var viewController: ShareKeyViaPhoneViewController!
    private let router = ShareKeyViaPhoneRoutingMock()
    private let exposureController = ExposureControllingMock()
    private let exposureStateStream = ExposureStateStreamingMock()
    private var interfaceOrientationStream = InterfaceOrientationStreamingMock()
    private var mockCardListener: CardListeningMock!
    private var mockExposureDataController: ExposureDataControllingMock!
    private var mockPauseController: PauseControllingMock!

    override func setUp() {
        super.setUp()

        recordSnapshots = false || forceRecordAllSnapshots

        mockCardListener = CardListeningMock()
        mockExposureDataController = ExposureDataControllingMock()
        interfaceOrientationStream.isLandscape = BehaviorSubject(value: false)
        mockPauseController = PauseControllingMock()

        exposureStateStream.exposureState = .just(ExposureState(
            notifiedState: .notNotified,
            activeState: .active
        ))

        viewController = ShareKeyViaPhoneViewController(theme: theme,
                                                        exposureController: exposureController,
                                                        exposureStateStream: exposureStateStream,
                                                        interfaceOrientationStream: interfaceOrientationStream,
                                                        withBackButton: false)
        viewController.router = router
    }

    // MARK: - Tests

    func test_snapshotStateLoading() {
        viewController.state = .loading
        snapshots(matching: viewController, waitForMainThread: true)
    }

    func test_snapshotStateSuccess() {
        viewController.state = .success(confirmationKey: LabConfirmationKey(identifier: "key here",
                                                                            bucketIdentifier: Data(),
                                                                            confirmationKey: Data(),
                                                                            validUntil: currentDate()))
        snapshots(matching: viewController, waitForMainThread: true)
    }

    func test_snapshotStateError() {
        viewController.state = .error
        snapshots(matching: viewController, waitForMainThread: true)
    }

    func test_errorCard() {
        viewController.state = .success(confirmationKey: LabConfirmationKey(identifier: "key here",
                                                                            bucketIdentifier: Data(),
                                                                            confirmationKey: Data(),
                                                                            validUntil: currentDate()))

        let cardViewController = CardViewController(listener: mockCardListener,
                                                    theme: theme,
                                                    types: [.exposureOff],
                                                    dataController: mockExposureDataController,
                                                    pauseController: mockPauseController)

        viewController.set(cardViewController: cardViewController)

        snapshots(matching: viewController, waitForMainThread: true)
    }

//    func test_viewDidLoad_calls_exposureController() {
//        XCTAssertNotNil(viewController.viewDidLoad())
//        XCTAssertTrue(exposureController.requestLabConfirmationKeyCallCount > 0)
//    }
}
