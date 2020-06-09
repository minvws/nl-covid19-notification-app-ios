/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import EN
import Foundation
import XCTest

final class RequestTestRouterTests: XCTestCase {
    private let viewController = RequestTestViewControllableMock()
    private let listener = RequestTestListenerMock()

    private var router: RequestTestRouter!

    override func setUp() {
        super.setUp()

        // TODO: Add other dependencies
        router = RequestTestRouter(listener: listener,
                                   viewController: viewController)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }

    // TODO: Add more tests
}
