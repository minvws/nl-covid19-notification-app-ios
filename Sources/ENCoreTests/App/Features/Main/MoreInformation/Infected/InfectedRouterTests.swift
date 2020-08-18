/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class InfectedRouterTests: XCTestCase {
    private let viewController = InfectedViewControllableMock()
    private let listener = InfectedListenerMock()

    private var router: InfectedRouter!

    override func setUp() {
        super.setUp()

        router = InfectedRouter(listener: listener,
                                viewController: viewController,
                                thankYouBuilder: ThankYouBuildableMock(),
                                cardBuilder: CardBuildableMock(),
                                helpDetailBuilder: HelpDetailBuildableMock())
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }
}
