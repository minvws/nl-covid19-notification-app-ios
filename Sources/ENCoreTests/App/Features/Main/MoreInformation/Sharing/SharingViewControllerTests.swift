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

final class SharingViewControllerTests: TestCase {
    private var viewController: ShareSheetViewController!
    private let listener = ShareSheetListenerMock()
    private var interfaceOrientationStream = InterfaceOrientationStreamingMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        interfaceOrientationStream.isLandscape = BehaviorSubject(value: false)

        viewController = ShareSheetViewController(listener: listener,
                                                  theme: theme,
                                                  interfaceOrientationStream: interfaceOrientationStream)
        
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
    }

    // MARK: - Tests

    func test_snapshot_shareSheetViewController() {
        snapshots(matching: viewController)
    }
}
