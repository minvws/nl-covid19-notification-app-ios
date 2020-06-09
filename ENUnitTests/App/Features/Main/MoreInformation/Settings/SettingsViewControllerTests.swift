/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import EN
import Foundation
import XCTest

final class SettingsViewControllerTests: XCTestCase {
    private var viewController: SettingsViewController!
    private let listener = SettingsListenerMock()

    override func setUp() {
        super.setUp()

        // TODO: Set up other components properly and connect them to the viewController
        viewController = SettingsViewController(listener: listener)
    }

    // TODO: Write test cases
    func test_case() {}
}
