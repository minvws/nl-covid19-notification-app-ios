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

final class InfectedViewControllerSnapshotTests: TestCase {
    private var viewController: InfectedViewController!
    private let router = InfectedRoutingMock()
    private let exposureController = ExposureControllingMock()
    private let exposureStateStream = ExposureStateStreamingMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        exposureStateStream.exposureState = Just(ExposureState(
            notifiedState: .notNotified,
            activeState: .active
        ))
            .eraseToAnyPublisher()

        viewController = InfectedViewController(theme: theme,
                                                exposureController: exposureController,
                                                exposureStateStream: exposureStateStream)
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
        let cardViewController = CardViewController(theme: theme,
                                                    type: .exposureOff)
        viewController.set(cardViewController: cardViewController)

        snapshots(matching: viewController)
    }

    func test_viewDidLoad_calls_exposureController() {
        XCTAssertNotNil(viewController.view)
        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 1)
    }
}
