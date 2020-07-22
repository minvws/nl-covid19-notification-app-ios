/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import EN
import ENFoundation
import Foundation
import XCTest

final class ___VARIABLE_componentName___ViewControllerTests: XCTestCase {
    private var viewController: ___VARIABLE_componentName___ViewController!
    private let router = ___VARIABLE_componentName___RoutingMock()
    // TODO: Add other dependencies

    override func setUp() {
        super.setUp()

        let theme = ENTheme()

        viewController = ___VARIABLE_componentName___ViewController(theme: theme)
        viewController.router = router
    }

    // TODO: Add tests
}
