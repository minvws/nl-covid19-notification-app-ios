/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import XCTest

class MessageManagerTests: TestCase {

    private var sut: MessageManager!
    private var mockStorageController: StorageControllingMock!

    override func setUpWithError() throws {
        mockStorageController = StorageControllingMock()

        sut = MessageManager(storageController: mockStorageController, theme: theme)
    }

    func test_getLocalizedTreatmentPerspective_shouldGetPerspectiveFromStorageController() throws {
        // Arrange
        let calledStorageControllerExpectation = expectation(description: "called storagecontroller")

        let exposureDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28

        mockStorageController.retrieveDataHandler = { key in
            XCTAssertTrue(key is CodableStorageKey<TreatmentPerspective>)
            calledStorageControllerExpectation.fulfill()
            return try! JSONEncoder().encode(TreatmentPerspective.fallbackMessage)
        }

        // Act
        let result = sut.getLocalizedTreatmentPerspective(withExposureDate: exposureDate)

        // Assert
        waitForExpectations(timeout: 2.0, handler: nil)
        XCTAssertNotNil(result)
    }

    func test_getLocalizedTreatmentPerspective_nonExistingLanguageShouldReturnEmptyMessage() throws {
        // Arrange
        let calledStorageControllerExpectation = expectation(description: "called storagecontroller")

        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "BLAH_BLAH" // non-existing language identifier
        let exposureDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28

        mockStorageController.retrieveDataHandler = { key in
            XCTAssertTrue(key is CodableStorageKey<TreatmentPerspective>)
            calledStorageControllerExpectation.fulfill()
            return try! JSONEncoder().encode(TreatmentPerspective.fallbackMessage)
        }

        // Act
        let result = sut.getLocalizedTreatmentPerspective(withExposureDate: exposureDate)

        // Assert
        waitForExpectations(timeout: 2.0, handler: nil)
        XCTAssertEqual(result, LocalizedTreatmentPerspective.emptyMessage)
    }

    func test_getLocalizedTreatmentPerspective_shouldReplacePlaceHolders() throws {
        // Arrange
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "en"
        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593624480) // 01/07/20 17:28

        let exposureDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28

        mockStorageController.retrieveDataHandler = { key in
            return try! JSONEncoder().encode(self.fakeTreatmentPerspectiveWithPlaceholders)
        }

        // Act
        let result = sut.getLocalizedTreatmentPerspective(withExposureDate: exposureDate)

        // Assert
        XCTAssertEqual(result.paragraphs.count, 2)
        XCTAssertEqual(result.paragraphs.first?.title.string, "Title ExposureDate:June 30, 2020, ExposureDaysAgo:1 day ago, StayHomeUntilDate:July 10, 2020")
        XCTAssertEqual(result.paragraphs.first?.body.string, "Body ExposureDate:June 30, 2020, ExposureDaysAgo:1 day ago, StayHomeUntilDate:July 10, 2020")
        XCTAssertEqual(result.paragraphs.last?.title.string, "Title 2")
        XCTAssertEqual(result.paragraphs.last?.body.string, "Body 2")
    }

    func test_getLocalizedTreatmentPerspective_shouldFormatBulletPoints() throws {
        // Arrange
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "en"
        let exposureDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28

        mockStorageController.retrieveDataHandler = { key in
            return try! JSONEncoder().encode(self.fakeTreatmentPerspectiveWithBulletPoints)
        }

        // Act
        let result = sut.getLocalizedTreatmentPerspective(withExposureDate: exposureDate)

        // Assert
        XCTAssertEqual(result.paragraphs.count, 1)
        XCTAssertEqual(result.paragraphs.first?.title.string, "Title")
        XCTAssertEqual(result.paragraphs.first?.body.string, "●\tsome bullet point\n●\tanother bullet point\nand some followup text")
    }

    private var fakeTreatmentPerspectiveWithPlaceholders: TreatmentPerspective {
        TreatmentPerspective(
            resources: ["en": [
                "some_resource_title": "Title ExposureDate:{ExposureDate}, ExposureDaysAgo:{ExposureDaysAgo}, StayHomeUntilDate:{StayHomeUntilDate}",
                "some_resource_body": "Body ExposureDate:{ExposureDate}, ExposureDaysAgo:{ExposureDaysAgo}, StayHomeUntilDate:{StayHomeUntilDate}",
                "some_resource_title2": "Title 2",
                "some_resource_body2": "Body 2"
            ]],
            guidance: .init(quarantineDays: 10,
                            layout: [
                                .init(title: "some_resource_title", body: "some_resource_body", type: "paragraph"),
                                .init(title: "some_resource_title2", body: "some_resource_body2", type: "paragraph"),
                                .init(title: "some_resource_title2", body: "some_resource_body2", type: "some-unknown-type")
                            ]
            )
        )
    }

    private var fakeTreatmentPerspectiveWithBulletPoints: TreatmentPerspective {
        TreatmentPerspective(
            resources: ["en": [
                "some_resource_title": "Title",
                "some_resource_body": "<ul><li>some bullet point</li><li>another bullet point</li></ul>and some followup text"
            ]],
            guidance: .init(quarantineDays: 10, layout: [.init(title: "some_resource_title", body: "some_resource_body", type: "paragraph")])
        )
    }
}
