/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ExposureNotification
import Foundation
import XCTest

final class ExposureManagerTests: TestCase {
    private var manager: ExposureManager!
    private let mock = ENManagingMock()

    override func setUp() {
        super.setUp()

        manager = ExposureManager(manager: mock)
    }

    func test_deinit_callsDeactivate() {
        XCTAssertEqual(mock.invalidateCallCount, 0)

        manager = nil

        XCTAssertEqual(mock.invalidateCallCount, 1)
    }

    func test_activate_callsManager_returnsExposureNotificationStatusWhenNoError() {
        mock.activateHandler = { completion in
            completion(nil)
        }

        ENManagingMock.authorizationStatus = .authorized
        mock.exposureNotificationStatus = .active

        XCTAssertEqual(mock.activateCallCount, 0)

        manager.activate { status in
            XCTAssertEqual(status, .active)
        }

        XCTAssertEqual(mock.activateCallCount, 1)
    }

    func test_activate_callsManager_returnsInactivateStateWhenError() {
        mock.activateHandler = { completion in
            completion(ENError(.internal))
        }

        XCTAssertEqual(mock.activateCallCount, 0)

        manager.activate { status in
            XCTAssertEqual(status, ExposureManagerStatus.inactive(.unknown))
        }

        XCTAssertEqual(mock.activateCallCount, 1)
    }
}
