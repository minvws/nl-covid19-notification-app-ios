/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import Foundation
import RxSwift
import SnapshotTesting
import XCTest

final class InfectedViewControllerTests: TestCase {
    private var viewController: InfectedViewController!
    private let router = InfectedRoutingMock()
    private let exposureController = ExposureControllingMock()
    private let exposureStateStream = ExposureStateStreamingMock()
    private let exposureStateSubject = PassthroughSubject<ExposureState, Never>()
    private var interfaceOrientationStream = InterfaceOrientationStreamingMock()

    override func setUp() {
        super.setUp()

        interfaceOrientationStream.isLandscape = BehaviorSubject(value: false)

        viewController = InfectedViewController(theme: theme,
                                                exposureController: exposureController,
                                                exposureStateStream: exposureStateStream,
                                                interfaceOrientationStream: interfaceOrientationStream)
        viewController.router = router

        exposureStateStream.exposureState = exposureStateSubject.eraseToAnyPublisher()

        // force viewDidLoad
        _ = viewController.view
    }

    func test_inactiveState_callsRouterToShowCard() {
        XCTAssertEqual(router.showInactiveCardCallCount, 0)

        exposureStateSubject.send(.init(notifiedState: .notNotified,
                                        activeState: .authorizationDenied))

        XCTAssertEqual(router.showInactiveCardCallCount, 1)
    }

    func test_activeState_callsRouterToRemoveAnyCard() {
        XCTAssertEqual(router.removeInactiveCardCallCount, 0)

        exposureStateSubject.send(.init(notifiedState: .notNotified,
                                        activeState: .active))

        XCTAssertEqual(router.removeInactiveCardCallCount, 1)
    }

    func test_activeState_requestsLabConfirmationKey() {
        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 0)

        exposureStateSubject.send(.init(notifiedState: .notNotified,
                                        activeState: .active))

        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 1)
    }

    func test_inactiveState_doesNotRequestLabConfirmationKey() {
        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 0)

        exposureStateSubject.send(.init(notifiedState: .notNotified,
                                        activeState: .authorizationDenied))

        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 0)
    }
}
