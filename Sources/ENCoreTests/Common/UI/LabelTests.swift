/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

class LabelTests: TestCase {

    private var sut: Label!

    override func setUpWithError() throws {
        sut = Label()
    }

    func test_copy_shouldCopyTextToPasteBoard() throws {
        // Arrange
        sut.text = "Some Text"
        sut.textCanBeCopied()
        UIPasteboard.general.string = ""

        // Act
        sut.copy(nil)

        // Assert
        XCTAssertEqual(UIPasteboard.general.string, "Some Text")
    }

    func test_copy_shouldRemoveCharactersFromCopiedString() throws {
        // Arrange
        sut.text = "Some-Text"
        sut.textCanBeCopied(charactersToRemove: "-")
        UIPasteboard.general.string = ""

        // Act
        sut.copy(nil)

        // Assert
        XCTAssertEqual(UIPasteboard.general.string, "SomeText")
    }

    func test_copy_shouldRemoveGestureIfNotCopyable() throws {
        // Arrange
        sut.textCanBeCopied(true)
        XCTAssertTrue(sut.gestureRecognizers?.contains { $0 is UILongPressGestureRecognizer } ?? false)

        // Act
        sut.textCanBeCopied(false)

        // Assert
        XCTAssertTrue(sut.gestureRecognizers?.isEmpty == true)
    }
}
