/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import ENCore
import RxSwift

class KeySharingViewControllerTests: TestCase {

    private var sut: KeySharingViewController!
    private var mockRouter: KeySharingRoutingMock!
    private var mockInterfaceOrientationStream: InterfaceOrientationStreamingMock!
    override func setUp() {
        mockRouter = KeySharingRoutingMock()
        mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()
        mockInterfaceOrientationStream.isLandscape = BehaviorSubject(value: false)
        
        sut = KeySharingViewController(theme: theme, interfaceOrientationStream: mockInterfaceOrientationStream)
        sut.router = mockRouter
    }
            
    func test_snapshot_keySharingViewController() {
        snapshots(matching: sut, waitForMainThread: true)
    }
}
