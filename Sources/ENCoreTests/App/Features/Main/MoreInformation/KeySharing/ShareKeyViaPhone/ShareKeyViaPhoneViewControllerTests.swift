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

final class ShareKeyViaPhoneViewControllerTests: TestCase {
    private var viewController: ShareKeyViaPhoneViewController!
    private var mockRouter: ShareKeyViaPhoneRoutingMock!
    private var mockExposureController: ExposureControllingMock!
    private var mockExposureStateStream: ExposureStateStreamingMock!
    private var mockInterfaceOrientationStream: InterfaceOrientationStreamingMock!

    private let exposureStateSubject = PublishSubject<ExposureState>()

    override func setUp() {
        super.setUp()

        mockRouter = ShareKeyViaPhoneRoutingMock()
        mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()
        mockExposureController = ExposureControllingMock()
        mockExposureStateStream = ExposureStateStreamingMock(exposureState: exposureStateSubject, currentExposureState: .init(notifiedState: .notNotified, activeState: .notAuthorized))

        mockInterfaceOrientationStream.isLandscape = BehaviorSubject(value: false)

        viewController = ShareKeyViaPhoneViewController(theme: theme,
                                                        exposureController: mockExposureController,
                                                        exposureStateStream: mockExposureStateStream,
                                                        interfaceOrientationStream: mockInterfaceOrientationStream,
                                                        withBackButton: false)
        viewController.router = mockRouter

        // force viewDidLoad
        _ = viewController.view
    }

    func test_inactiveState_callsRouterToShowCard() {
        let completionExpectation = expectation(description: "completionExpectation")
        mockRouter.showInactiveCardHandler = { _ in
            completionExpectation.fulfill()
        }
        XCTAssertEqual(mockRouter.showInactiveCardCallCount, 0)

        exposureStateSubject.onNext(.init(notifiedState: .notNotified,
                                          activeState: .authorizationDenied))

        waitForExpectations()
        XCTAssertEqual(mockRouter.showInactiveCardCallCount, 1)
    }

    func test_activeState_callsRouterToRemoveAnyCard() {
        let completionExpectation = expectation(description: "completionExpectation")
        mockRouter.removeInactiveCardHandler = {
            completionExpectation.fulfill()
        }
        XCTAssertEqual(mockRouter.removeInactiveCardCallCount, 0)

        exposureStateSubject.onNext(.init(notifiedState: .notNotified,
                                          activeState: .active))

        waitForExpectations()
        XCTAssertEqual(mockRouter.removeInactiveCardCallCount, 1)
    }

    func test_activeState_requestsLabConfirmationKey() {
        let completionExpectation = expectation(description: "completionExpectation")
        mockExposureController.requestLabConfirmationKeyHandler = { _ in
            completionExpectation.fulfill()
        }
        XCTAssertEqual(mockExposureController.requestLabConfirmationKeyCallCount, 0)

        exposureStateSubject.onNext(.init(notifiedState: .notNotified,
                                          activeState: .active))

        waitForExpectations()
        XCTAssertEqual(mockExposureController.requestLabConfirmationKeyCallCount, 1)
    }

    func test_inactiveState_doesNotRequestLabConfirmationKey() {
        let completionExpectation = expectation(description: "completionExpectation")
        completionExpectation.isInverted = true
        mockExposureController.requestLabConfirmationKeyHandler = { _ in
            completionExpectation.fulfill()
        }

        XCTAssertEqual(mockExposureController.requestLabConfirmationKeyCallCount, 0)

        exposureStateSubject.onNext(.init(notifiedState: .notNotified,
                                          activeState: .authorizationDenied))

        waitForExpectations()
        XCTAssertEqual(mockExposureController.requestLabConfirmationKeyCallCount, 0)
    }
}
