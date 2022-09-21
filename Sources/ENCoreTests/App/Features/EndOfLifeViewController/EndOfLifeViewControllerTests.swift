/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import RxSwift
import SnapshotTesting
import XCTest

final class EndOfLifeViewControllerTests: TestCase {

    private var viewController: EndOfLifeViewController!
    private let listener = EndOfLifeListenerMock()
    private let storageController = StorageControllingMock()
    private let interfaceOrientationStream = InterfaceOrientationStreamingMock(isLandscape: BehaviorSubject(value: false), currentOrientationIsLandscape: false)

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false || forceRecordAllSnapshots

        viewController = EndOfLifeViewController(listener: listener, theme: theme, storageController: storageController, interfaceOrientationStream: interfaceOrientationStream)
    }

    // MARK: - Tests

    func disabled_test_snapshot_endOfLifeViewController() {
        snapshots(matching: viewController)
    }
}
