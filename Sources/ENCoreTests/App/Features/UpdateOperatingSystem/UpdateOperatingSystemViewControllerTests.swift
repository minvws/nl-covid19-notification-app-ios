/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import RxSwift
import SnapshotTesting
import XCTest

final class UpdateOperatingSystemViewControllerTests: TestCase {

    private var viewController: UpdateOperatingSystemViewController!
    private var mockInterfaceOrientationStream: InterfaceOrientationStreamingMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()
        mockInterfaceOrientationStream.isLandscape = BehaviorSubject(value: false)

        recordSnapshots = false

        viewController = UpdateOperatingSystemViewController(
            theme: theme,
            interfaceOrientationStream: mockInterfaceOrientationStream)
    }

    // MARK: - Tests

    func testSnapshotUpdateOperatingSystemViewController() {
        snapshots(matching: viewController)
    }
}
