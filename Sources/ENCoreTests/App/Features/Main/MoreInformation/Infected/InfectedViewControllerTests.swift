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
    private var mockRouter: InfectedRoutingMock!
    private var mockExposureController: ExposureControllingMock!
    private var mockExposureStateStream: ExposureStateStreamingMock!
    private var mockInterfaceOrientationStream: InterfaceOrientationStreamingMock!

    private let exposureStateSubject = PublishSubject<ExposureState>()

    override func setUp() {
        super.setUp()

        mockRouter = InfectedRoutingMock()
        mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()
        mockExposureController = ExposureControllingMock()
        mockExposureStateStream = ExposureStateStreamingMock(exposureState: exposureStateSubject)

        mockInterfaceOrientationStream.isLandscape = BehaviorSubject(value: false)

        viewController = InfectedViewController(theme: theme,
                                                exposureController: mockExposureController,
                                                exposureStateStream: mockExposureStateStream,
                                                interfaceOrientationStream: mockInterfaceOrientationStream)
        viewController.router = mockRouter

        // force viewDidLoad
        _ = viewController.view
    }

    func test_inactiveState_callsRouterToShowCard() {
        XCTAssertEqual(mockRouter.showInactiveCardCallCount, 0)

        exposureStateSubject.onNext(.init(notifiedState: .notNotified,
                                          activeState: .authorizationDenied))

        XCTAssertEqual(mockRouter.showInactiveCardCallCount, 1)
    }

    func test_activeState_callsRouterToRemoveAnyCard() {
        XCTAssertEqual(mockRouter.removeInactiveCardCallCount, 0)

        exposureStateSubject.onNext(.init(notifiedState: .notNotified,
                                          activeState: .active))

        XCTAssertEqual(mockRouter.removeInactiveCardCallCount, 1)
    }

    func test_activeState_requestsLabConfirmationKey() {
        XCTAssertEqual(mockExposureController.requestLabConfirmationKeyCallCount, 0)

        exposureStateSubject.onNext(.init(notifiedState: .notNotified,
                                          activeState: .active))

        XCTAssertEqual(mockExposureController.requestLabConfirmationKeyCallCount, 1)
    }

    func test_inactiveState_doesNotRequestLabConfirmationKey() {
        XCTAssertEqual(mockExposureController.requestLabConfirmationKeyCallCount, 0)

        exposureStateSubject.onNext(.init(notifiedState: .notNotified,
                                          activeState: .authorizationDenied))

        XCTAssertEqual(mockExposureController.requestLabConfirmationKeyCallCount, 0)
    }
}
