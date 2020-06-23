/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import SnapshotTesting
import XCTest

final class MoreInformationViewControllerTests: XCTestCase {
    private var viewController: MoreInformationViewController!
    private let listener = MoreInformationListenerMock()
    private let tableViewDelegate = UITableViewDelegateMock()
    private let tableViewDataSource = UITableViewDataSourceMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        SnapshotTesting.diffTool = "ksdiff"
        SnapshotTesting.record = false

        let theme = ENTheme()
        viewController = MoreInformationViewController(listener: listener,
                                                       theme: theme)
    }

    // MARK: - Tests

    func test_snapshot_moreInformationViewController() {
        assertSnapshot(matching: viewController, as: .image(size: CGSize(width: 414, height: 470)))
    }

    func test_didSelectItem_about() {
        viewController.didSelect(identifier: .about)

        XCTAssertEqual(listener.moreInformationRequestsAboutCallCount, 1)
    }

    func test_didSelectItem_infected() {
        viewController.didSelect(identifier: .infected)

        XCTAssertEqual(listener.moreInformationRequestsInfectedCallCount, 1)
    }

    func test_didSelectItem_receivedNotification() {
        viewController.didSelect(identifier: .receivedNotification)

        XCTAssertEqual(listener.moreInformationRequestsReceivedNotificationCallCount, 1)
    }

    func test_didSelectItem_requestTest() {
        viewController.didSelect(identifier: .requestTest)

        XCTAssertEqual(listener.moreInformationRequestsRequestTestCallCount, 1)
    }
}
