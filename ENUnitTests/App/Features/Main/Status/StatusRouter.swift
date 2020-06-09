/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

@testable import EN
import Foundation
import XCTest

final class StatusRouterTests: XCTestCase {
    private let viewController = StatusViewControllableMock()
    private let listener = StatusListenerMock()
    
    private var router: StatusRouter!
    
    override func setUp() {
        super.setUp()
        
        // TODO: Add other dependencies
        router = StatusRouter(listener: listener,
                              viewController: viewController)
    }
    
    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }
    
    // TODO: Add more tests
}
