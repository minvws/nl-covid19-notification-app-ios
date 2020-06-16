/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import EN
import Foundation
import XCTest

final class StoreControllerTests: XCTestCase {
    private var controller: StorageController!
    
    override class func setUp() {
        super.setUp()
        
        controller = StorageController()
    }
}
