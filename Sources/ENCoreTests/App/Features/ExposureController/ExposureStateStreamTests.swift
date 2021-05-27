/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import RxSwift
import XCTest

class ExposureStateStreamTests: TestCase {

    private var sut: ExposureStateStream!

    override func setUp() {
        super.setUp()
        sut = ExposureStateStream()
    }

    func test_update_shouldOnlyStreamDistinctValues() {

        let subscriptionCallsExpectation = expectation(description: "subscriptionCalled")
        subscriptionCallsExpectation.expectedFulfillmentCount = 2
        var lastActiveState: ExposureActiveState?

        sut.exposureState.subscribe { state in
            lastActiveState = state.element?.activeState
            subscriptionCallsExpectation.fulfill()
        }.disposed(by: disposeBag)

        sut.update(state: .init(notifiedState: .notNotified, activeState: .active))
        sut.update(state: .init(notifiedState: .notNotified, activeState: .active))
        sut.update(state: .init(notifiedState: .notNotified, activeState: .authorizationDenied))

        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertEqual(lastActiveState, .authorizationDenied)
    }
}
