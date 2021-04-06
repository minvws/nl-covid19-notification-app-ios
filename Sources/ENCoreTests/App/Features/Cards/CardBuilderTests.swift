/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import XCTest

@testable import ENCore

class CardBuilderTests: TestCase {
    private var sut: CardBuilder!
    private var mockCardDependency: CardDependencyMock!
    private var mockCardListener: CardListeningMock!

    override func setUp() {
        super.setUp()
        mockCardDependency = CardDependencyMock()
        mockCardDependency.theme = theme

        mockCardListener = CardListeningMock()

        sut = CardBuilder(dependency: mockCardDependency)
    }

    func test_build() throws {
        let result = sut.build(listener: mockCardListener, types: [.bluetoothOff, .exposureOff])

        let viewController = try XCTUnwrap(result.viewControllable as? CardViewController)

        XCTAssertTrue(viewController.listener === mockCardListener)
        XCTAssertTrue(viewController.theme === mockCardDependency.theme)
    }
}
