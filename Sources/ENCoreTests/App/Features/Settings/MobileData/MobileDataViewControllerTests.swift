/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import ENFoundation
import Foundation
import SnapshotTesting
import XCTest

final class MobileDataViewControllerTests: TestCase {
    private var sut: MobileDataViewController!
    private var mockListener: MobileDataListenerMock!

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        mockListener = MobileDataListenerMock()

        sut = MobileDataViewController(listener: mockListener,
                                       theme: theme)
    }

    // MARK: - Tests

    func testSnapshotDefaultState_mobileDataViewController() {
        snapshots(matching: sut)
    }
}
