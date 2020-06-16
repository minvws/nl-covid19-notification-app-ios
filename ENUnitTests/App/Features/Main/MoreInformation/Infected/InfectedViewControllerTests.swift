/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import EN
import Foundation
import XCTest

final class InfectedViewControllerTests: XCTestCase {
    private var viewController: InfectedViewController!
    private let router = InfectedRoutingMock()

    override func setUp() {
        super.setUp()
        
        let theme = ENTheme()

        viewController = InfectedViewController(theme: theme)
        viewController.router = router
    }

    // TODO: Add tests
}
