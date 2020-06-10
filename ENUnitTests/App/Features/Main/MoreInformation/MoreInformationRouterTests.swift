/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

@testable import EN
import Foundation
import XCTest

final class MoreInformationRouterTests: XCTestCase {
    private let viewController = MoreInformationViewControllableMock()
    private let listener = MoreInformationListenerMock()
    
    private var router: MoreInformationRouter!
    
    override func setUp() {
        super.setUp()
        
        router = MoreInformationRouter(listener: listener,
                                       viewController: viewController)
    }
    
    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }
}
