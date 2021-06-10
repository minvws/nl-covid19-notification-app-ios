/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import ENCore

class KeySharingViewControllerTests: TestCase {

    private var sut: KeySharingViewController!
    private var mockRouter: KeySharingRoutingMock!
    
    override func setUp() {
        mockRouter = KeySharingRoutingMock()
        sut = KeySharingViewController(theme: theme)
        sut.router = mockRouter
    }
            
    func test_snapshot_keySharingViewController() {
        snapshots(matching: sut, waitForMainThread: true)
    }
}
