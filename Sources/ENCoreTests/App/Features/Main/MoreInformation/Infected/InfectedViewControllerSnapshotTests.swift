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

final class InfectedViewControllerSnapshotTests: TestCase {
    private var viewController: InfectedViewController!
    private let router = InfectedRoutingMock()
    private let exposureController = ExposureControllingMock()
    private let exposureStateStream = ExposureStateStreamingMock()
    private var interfaceOrientationStream = InterfaceOrientationStreamingMock()
    private var mockCardListener: CardListeningMock!
    private var mockExposureDataController: ExposureDataControllingMock!
    private var mockPauseController: PauseControllingMock!

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        mockCardListener = CardListeningMock()
        mockExposureDataController = ExposureDataControllingMock()
        interfaceOrientationStream.isLandscape = BehaviorSubject(value: false)
        mockPauseController = PauseControllingMock()

        exposureStateStream.exposureState = .just(ExposureState(
            notifiedState: .notNotified,
            activeState: .active
        ))

        viewController = InfectedViewController(theme: theme,
                                                exposureController: exposureController,
                                                exposureStateStream: exposureStateStream,
                                                interfaceOrientationStream: interfaceOrientationStream)
        viewController.router = router
    }

    // MARK: - Tests

    func test_infected_snapshotStateLoading() {
        viewController.state = .loading
        snapshots(matching: viewController)
    }

    func test_infected_snapshotStateSuccess() {
        viewController.state = .success(confirmationKey: LabConfirmationKey(identifier: "key here",
                                                                            bucketIdentifier: Data(),
                                                                            confirmationKey: Data(),
                                                                            validUntil: Date()))
        snapshots(matching: viewController)
    }

    func test_infected_snapshotStateError() {
        viewController.state = .error
        snapshots(matching: viewController)
    }

    func test_infected_errorCard() {
        viewController.state = .success(confirmationKey: LabConfirmationKey(identifier: "key here",
                                                                            bucketIdentifier: Data(),
                                                                            confirmationKey: Data(),
                                                                            validUntil: Date()))

        let cardViewController = CardViewController(listener: mockCardListener,
                                                    theme: theme,
                                                    types: [.exposureOff],
                                                    dataController: mockExposureDataController,
                                                    pauseController: mockPauseController)

        viewController.set(cardViewController: cardViewController)

        snapshots(matching: viewController)
    }

    func test_viewDidLoad_calls_exposureController() {
        XCTAssertNotNil(viewController.view)
        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 1)
    }
}
