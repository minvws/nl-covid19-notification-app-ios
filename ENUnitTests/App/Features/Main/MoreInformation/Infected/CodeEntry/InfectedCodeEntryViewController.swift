/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

@testable import EN
import Foundation
import XCTest

final class InfectedCodeEntryViewControllerTests: XCTestCase {
    private var viewController: InfectedCodeEntryViewController!
    private let listener = InfectedCodeEntryListenerMock()
    
    override func setUp() {
        super.setUp()
        
        // TODO: Set up other components properly and connect them to the viewController
        viewController = InfectedCodeEntryViewController(listener: listener)
    }
    
    // TODO: Write test cases
    func test_case() {

    }
}
