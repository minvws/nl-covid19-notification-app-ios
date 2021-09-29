/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class TechnicalInformationRouterTests: TestCase {

    private let mockApplicationController = ApplicationControllingMock()
    private let mockViewController = TechnicalInformationViewControllableMock()
    private var sut: TechnicalInformationRouter!

    override func setUp() {
        super.setUp()
        sut = TechnicalInformationRouter(viewController: mockViewController, applicationController: mockApplicationController)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(mockViewController.routerSetCallCount, 1)
    }

    func test_routeToGithubPage() {
        // Arrange
        XCTAssertEqual(mockApplicationController.openCallCount, 0)

        // Act
        sut.routeToGithubPage()

        // Assert
        XCTAssertEqual(mockApplicationController.openCallCount, 1)
    }
}
