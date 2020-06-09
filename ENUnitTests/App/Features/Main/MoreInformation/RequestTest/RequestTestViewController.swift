/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

@testable import EN
import Foundation
import XCTest

final class RequestTestViewControllerTests: XCTestCase {
    private var viewController: RequestTestViewController!
    private let router = RequestTestRoutingMock()
    
    override func setUp() {
        super.setUp()
        
        viewController = RequestTestViewController()
        viewController.router = router
    }
    
    // TODO: Add tests
}
