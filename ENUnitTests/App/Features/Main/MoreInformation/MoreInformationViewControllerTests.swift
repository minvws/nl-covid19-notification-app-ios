/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import EN
import Foundation
import XCTest

final class MoreInformationViewControllerTests: XCTestCase {
    private var viewController: MoreInformationViewController!
    private let listener = MoreInformationListenerMock()
    private let tableController = MoreInformationTableControllingMock()
    private let tableViewDelegate = UITableViewDelegateMock()
    private let tableViewDataSource = UITableViewDataSourceMock()

    override func setUp() {
        super.setUp()

        let theme = ENTheme()

        tableController.dataSource = tableViewDataSource
        tableController.delegate = tableViewDelegate

        viewController = MoreInformationViewController(listener: listener,
                                                       theme: theme,
                                                       tableController: tableController)
    }

    func test_viewDidLoad_setsCells() {
        var receivedCells: [MoreInformationCell]?
        tableController.setHandler = { cells in receivedCells = cells }

        XCTAssertEqual(tableController.setCallCount, 0)

        _ = viewController.view

        XCTAssertEqual(tableController.setCallCount, 1)
        XCTAssertNotNil(receivedCells)
        XCTAssertEqual(receivedCells?.count, 4)
    }
}
