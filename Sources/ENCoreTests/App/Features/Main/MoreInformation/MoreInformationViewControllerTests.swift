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
import SnapKit
import SnapshotTesting
import XCTest

final class MoreInformationViewControllerTests: TestCase {

    private var viewController: MoreInformationViewController!
    private let listener = MoreInformationListenerMock()
    private let tableViewDelegate = UITableViewDelegateMock()
    private let tableViewDataSource = UITableViewDataSourceMock()
    private let exposureControllerMock = ExposureControllingMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        let date = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        DateTimeTestingOverrides.overriddenCurrentDate = date

        exposureControllerMock.lastTEKProcessingDateHandler = {
            return Just(date).eraseToAnyPublisher()
        }

        viewController = MoreInformationViewController(
            listener: listener,
            theme: theme,
            bundleInfoDictionary: [
                "CFBundleShortVersionString": "1.0",
                "CFBundleVersion": "12345",
                "GitHash": "5ec9b"
            ],
            exposureController: exposureControllerMock
        )
    }

    // MARK: - Tests

    func test_snapshot_moreInformationViewController() {
        assertSnapshot(matching: wrapped(viewController.view), as: .recursiveDescription)
    }

    func test_didSelectItem_settings() {
        viewController.didSelect(identifier: .settings)

        XCTAssertEqual(listener.moreInformationRequestsSettingsCallCount, 1)
    }

    func test_didSelectItem_about() {
        viewController.didSelect(identifier: .about)

        XCTAssertEqual(listener.moreInformationRequestsAboutCallCount, 1)
    }

    func test_didSelectItem_share() {
        viewController.didSelect(identifier: .share)

        XCTAssertEqual(listener.moreInformationRequestsSharingCallCount, 1)
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

    private func wrapped(_ wrappedView: UIView) -> UIView {
        let view = UIView(frame: .zero)
        view.snp.makeConstraints { maker in
            maker.width.equalTo(320)
        }

        view.addSubview(wrappedView)
        wrappedView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.top.equalToSuperview()
        }

        return view
    }
}
