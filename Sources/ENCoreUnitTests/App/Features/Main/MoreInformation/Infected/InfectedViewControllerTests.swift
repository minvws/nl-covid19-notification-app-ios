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

final class InfectedViewControllerTests: XCTestCase {
    private var viewController: InfectedViewController!
    private let router = InfectedRoutingMock()
    private let exposureController = ExposureControllingMock()

    override func setUp() {
        super.setUp()

        SnapshotTesting.record = false

        let theme = ENTheme()

        viewController = InfectedViewController(theme: theme, exposureController: exposureController)
        viewController.router = router
    }

    // MARK: - Tests

    func test_infected_snapshotStateLoading() {
        viewController.state = .loading
        assertSnapshot(matching: viewController, as: .image())
    }

    func test_infected_snapshotStateSuccess() {
        viewController.state = .success(confirmationKey: LabConfirmationKey(identifier: "key here",
                                                                            bucketIdentifier: Data(),
                                                                            confirmationKey: Data(),
                                                                            validUntil: Date()))
        assertSnapshot(matching: viewController, as: .image())
    }

    func test_infected_snapshotStateError() {
        viewController.state = .error
        assertSnapshot(matching: viewController, as: .image())
    }

    func test_viewDidLoad_calls_exposureController() {
        XCTAssertNotNil(viewController.view)
        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 1)
    }
}
