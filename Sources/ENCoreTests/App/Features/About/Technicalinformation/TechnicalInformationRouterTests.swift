/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class TechnicalInformationRouterTests: TestCase {

    private let viewController = TechnicalInformationViewControllableMock()
    private var router: TechnicalInformationRouter!

    override func setUp() {
        super.setUp()
        router = TechnicalInformationRouter(viewController: viewController)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }
}
