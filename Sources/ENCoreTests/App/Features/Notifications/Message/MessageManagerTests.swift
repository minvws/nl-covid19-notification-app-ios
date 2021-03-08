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

    func test_getLocalizedTreatmentPerspective_nonExistingStringForLanguageShouldDefaultToEnglish() throws {
        // Arrange
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "fr"
        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593624480) // 01/07/20 17:28
        let exposureDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28

        mockStorageController.retrieveDataHandler = { key in
            return try! JSONEncoder().encode(self.fakeTreatmentPerspectiveWithPlaceholders)
        }

        // Act
        let result = sut.getLocalizedTreatmentPerspective(withExposureDate: exposureDate)

        // Assert
        XCTAssertEqual(result.paragraphs.count, 2)
        XCTAssertEqual(result.paragraphs.last?.title, "Title 2 French")
        XCTAssertEqual(result.paragraphs.last?.body.first?.string, "Body 2") // Uses english resource because french stirng doesn't exist
    }

    func test_getLocalizedTreatmentPerspective_shouldReplacePlaceHolders() {
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
        XCTAssertEqual(result.paragraphs.first?.title, "Title ExposureDate:Tuesday, June 30, ExposureDateWithCalculation:Monday, July 20, ExposureDateShort:June 30, ExposureDateShortWithCalculation:July 2, ExposureDaysAgo:1 day ago, StayHomeUntilDate:Friday, July 10")
        XCTAssertEqual(result.paragraphs.first?.body.first?.string, "Body ExposureDate:Tuesday, June 30, ExposureDateWithCalculation:Monday, July 20, ExposureDateShort:June 30, ExposureDateShortWithCalculation:July 2, ExposureDaysAgo:1 day ago, StayHomeUntilDate:Friday, July 10")
        XCTAssertEqual(result.paragraphs.last?.title, "Title 2")
        XCTAssertEqual(result.paragraphs.last?.body.first?.string, "Body 2")
    }

    func test_getLocalizedTreatmentPerspective_shouldReplacePlaceHolders_Arabic() throws {
        // Arrange
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "ar"
        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593624480) // 01/07/20 17:28

        let exposureDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28

        mockStorageController.retrieveDataHandler = { key in

            let initialBodyString = self.fakeTreatmentPerspectiveWithPlaceholders.resources["ar"]!["some_resource_body"]!
            XCTAssertTrue(initialBodyString.contains("{ExposureDate+5}"))
            XCTAssertTrue(initialBodyString.contains("{ExposureDate+10}"))

            return try! JSONEncoder().encode(self.fakeTreatmentPerspectiveWithPlaceholders)
        }

        // Act
        let result = sut.getLocalizedTreatmentPerspective(withExposureDate: exposureDate)

        // Assert
        let bodyString = try XCTUnwrap(result.paragraphs.first?.body.first?.string)
        XCTAssertFalse(bodyString.contains("{ExposureDate+5}"))
        XCTAssertFalse(bodyString.contains("{ExposureDate+10}"))
    }

    func test_getLocalizedTreatmentPerspective_unknownPlaceHolderShouldNotbeReplaced() throws {
        // Arrange
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "en"
        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593624480) // 01/07/20 17:28

        let exposureDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        let treatmentPerspective = TreatmentPerspective(
            resources: [
                "en": ["some_resource_title": "{SomeUnknownPlaceholder} {ExposureDate}, {ExposureDate+0}", "some_resource_body": "{SomeUnknownPlaceholder} {ExposureDate}"]
            ],
            guidance: .init(
                quarantineDays: 10,
                layout: [.init(title: "some_resource_title", body: "some_resource_body", type: "paragraph")]
            )
        )

        mockStorageController.retrieveDataHandler = { key in
            return try! JSONEncoder().encode(treatmentPerspective)
        }

        // Act
        let result = sut.getLocalizedTreatmentPerspective(withExposureDate: exposureDate)

        // Assert
        XCTAssertEqual(result.paragraphs.first?.title, "{SomeUnknownPlaceholder} Tuesday, June 30, Tuesday, June 30")
        XCTAssertEqual(result.paragraphs.first?.body.first?.string, "{SomeUnknownPlaceholder} Tuesday, June 30")
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
        XCTAssertEqual(result.paragraphs.first?.title, "Title")
        XCTAssertEqual(result.paragraphs.first?.body[0].string, "●\tsome bullet point")
        XCTAssertEqual(result.paragraphs.first?.body[1].string, "●\tanother bullet point")
        XCTAssertEqual(result.paragraphs.first?.body[2].string, "and some followup text")
    }

    /// Makes sure all the resource keys are available in all languages
    func test_defaultTreatmentPerspective_sanityCheck() {
        let model = TreatmentPerspective.fallbackMessage

        // Quarantine days must be set
        XCTAssertNotEqual(model.guidance.quarantineDays, 0)

        // English (base) resource should always be available
        XCTAssertTrue(model.resources.contains(where: { $0.key == "en" }))

        // All referenced resource keys must be available in all languages
        model.guidance.layout.forEach { layoutElement in
            model.resources.forEach { resource in
                if let title = layoutElement.title {
                    XCTAssertNotNil(resource.value[title], "resource with key `\(resource.key)` does not contain string with key `\(title)`")
                }
                if let body = layoutElement.body {
                    XCTAssertNotNil(resource.value[body], "resource with key `\(resource.key)` does not contain string with key `\(body)`")
                }
                XCTAssertNotNil(LocalizedTreatmentPerspective.Paragraph.ParagraphType(rawValue: layoutElement.type), "paragraph type is not implemented in app")
            }
        }
    }

    // MARK: - Private

    private var fakeTreatmentPerspectiveWithPlaceholders: TreatmentPerspective {
        TreatmentPerspective(
            resources: [
                "en": [
                    "some_resource_title": "Title ExposureDate:{ExposureDate}, ExposureDateWithCalculation:{ExposureDate+20}, ExposureDateShort:{ExposureDateShort}, ExposureDateShortWithCalculation:{ExposureDateShort+2}, ExposureDaysAgo:{ExposureDaysAgo}, StayHomeUntilDate:{StayHomeUntilDate}",
                    "some_resource_body": "Body ExposureDate:{ExposureDate}, ExposureDateWithCalculation:{ExposureDate+20}, ExposureDateShort:{ExposureDateShort}, ExposureDateShortWithCalculation:{ExposureDateShort+2}, ExposureDaysAgo:{ExposureDaysAgo}, StayHomeUntilDate:{StayHomeUntilDate}",
                    "some_resource_title2": "Title 2",
                    "some_resource_body2": "Body 2"
                ],
                "fr": [
                    "some_resource_title2": "Title 2 French"
                ],
                "ar": [
                    "some_resource_title": "Title",
                    "some_resource_body": "<ul><li>هل ظهرت لديك مؤخرًا أعراض جديدة تتناسب مع فيروس كورونا؟ قم بإجراء اختبار كورونا في أسرع وقت ممكن.</li><li> أليست لديك أعراض؟ اتصل من أجل إجراء اختبار كورونا في أو بعد {ExposureDate+5}. فقط اعتبارًا من هذا التاريخ تكون نتيجة اختبار كورونا في حالتك موثوقة بدرجة كافية. </li><li> ألم تتمكن من إجراء الاختبار؟ ابق في المنزل حتى{ExposureDate+10}. تستطيع بعد ذلك الخروج من المنزل إذا لم تظهر لديك أعراض.</li><li> هل لديك أعراض خطيرة كارتفاع درجة الحرارة أو صعوبة في التنفس؟ أم أنك من ضمن مجموعة معرضة للخطر وأصبت بالحمى؟ اتصل بطبيبك أولاً </li></ul>\n<b> هل تعطيك الـ GGD عبر الهاتف نصائح مختلفة عن النصائح الموجودة في التطبيق؟ اتبع إذًا نصيحة الـ GGD.</b>",
                    "some_resource_title2": "Title 2",
                    "some_resource_body2": "<ul><li>هل ظهرت لديك مؤخرًا أعراض جديدة تتناسب مع فيروس كورونا؟ قم بإجراء اختبار كورونا في أسرع وقت ممكن.</li><li> أليست لديك أعراض؟ اتصل من أجل إجراء اختبار كورونا في أو بعد {ExposureDate+5}. فقط اعتبارًا من هذا التاريخ تكون نتيجة اختبار كورونا في حالتك موثوقة بدرجة كافية. </li><li> ألم تتمكن من إجراء الاختبار؟ ابق في المنزل حتى{ExposureDate+10}. تستطيع بعد ذلك الخروج من المنزل إذا لم تظهر لديك أعراض.</li><li> هل لديك أعراض خطيرة كارتفاع درجة الحرارة أو صعوبة في التنفس؟ أم أنك من ضمن مجموعة معرضة للخطر وأصبت بالحمى؟ اتصل بطبيبك أولاً </li></ul>\n<b> هل تعطيك الـ GGD عبر الهاتف نصائح مختلفة عن النصائح الموجودة في التطبيق؟ اتبع إذًا نصيحة الـ GGD.</b>"
                ]
            ],
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
