/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

@testable import EN
import Foundation
import XCTest

final class ___VARIABLE_componentName___RouterTests: XCTestCase {
    private let viewController = ___VARIABLE_componentName___ViewControllableMock()
    // TODO: Add additional childBuilders / dependencies
    
    private var router: ___VARIABLE_componentName___Router!
    
    override func setUp() {
        super.setUp()
        
        // TODO: Add other dependencies
        router = ___VARIABLE_componentName___Router(viewController: viewController)
    }
    
    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }
    
    // TODO: Add more tests
}
