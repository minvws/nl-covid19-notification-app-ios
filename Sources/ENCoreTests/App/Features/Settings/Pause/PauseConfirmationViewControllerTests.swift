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

final class PauseConfirmationViewControllerTests: TestCase {
    private var sut: PauseConfirmationViewController!
    private var mockListener: PauseConfirmationListenerMock!
    private var mockPauseController: PauseControllingMock!

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        mockListener = PauseConfirmationListenerMock()
        mockPauseController = PauseControllingMock()

        sut = PauseConfirmationViewController(theme: theme,
                                              listener: mockListener,
                                              pauseController: mockPauseController)
    }

    // MARK: - Tests

    func testSnapshotDefaultState() {
        snapshots(matching: sut)
    }
}
