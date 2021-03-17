/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import RxSwift
import SnapshotTesting
import XCTest

final class MessageViewControllerTests: TestCase {

    private var viewController: MessageViewController!
    private var listener: MessageListenerMock!
    private var storageController: StorageControllingMock!
    private var messageManager: MessageManagingMock!
    private var exposureDate: Date!
    private let mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()
    private let dataController = ExposureDataControllingMock()

    override func setUp() {
        super.setUp()

        listener = MessageListenerMock()
        storageController = StorageControllingMock()
        messageManager = MessageManagingMock()

        LocalizationOverrides.overriddenIsRTL = nil

        recordSnapshots = false
        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        exposureDate = Date(timeIntervalSince1970: 1593290000) // 27/06/20 20:33

        mockInterfaceOrientationStream.isLandscape = BehaviorSubject(value: false)
    }

    // MARK: - Tests

    func testSnapshotMessageViewController_withListAndText() {

        messageManager.getLocalizedTreatmentPerspectiveHandler = { date in
            self.fakeMessageWithListAndText
        }

        viewController = MessageViewController(listener: listener, theme: theme, exposureDate: exposureDate, interfaceOrientationStream: mockInterfaceOrientationStream, dataController: dataController, messageManager: messageManager)

        snapshots(matching: viewController)
    }

    func testSnapshotMessageViewController_withListOnly() {

        messageManager.getLocalizedTreatmentPerspectiveHandler = { date in
            self.fakeMessageWithListOnly
        }

        viewController = MessageViewController(listener: listener, theme: theme, exposureDate: exposureDate, interfaceOrientationStream: mockInterfaceOrientationStream, dataController: dataController, messageManager: messageManager)
        snapshots(matching: viewController)
    }

    func testSnapshotMessageViewController_withoutList() {
        messageManager.getLocalizedTreatmentPerspectiveHandler = { date in
            self.fakeMessageWithoutList
        }

        viewController = MessageViewController(listener: listener, theme: theme, exposureDate: exposureDate, interfaceOrientationStream: mockInterfaceOrientationStream, dataController: dataController, messageManager: messageManager)
        snapshots(matching: viewController)
    }

    func testSnapshotMessageViewController_rtl() {
        LocalizationOverrides.overriddenIsRTL = true

        messageManager.getLocalizedTreatmentPerspectiveHandler = { date in
            self.fakeMessageRTLWithList
        }

        viewController = MessageViewController(listener: listener, theme: theme, exposureDate: exposureDate, interfaceOrientationStream: mockInterfaceOrientationStream, dataController: dataController, messageManager: messageManager)
        snapshots(matching: viewController)

        LocalizationOverrides.overriddenIsRTL = nil
    }

    func testPresentationControllerDidDismissCallsListener() {
        messageManager.getLocalizedTreatmentPerspectiveHandler = { date in
            self.fakeMessageWithListAndText
        }

        viewController = MessageViewController(listener: listener, theme: theme, exposureDate: exposureDate, interfaceOrientationStream: mockInterfaceOrientationStream, dataController: dataController, messageManager: messageManager)
        listener.messageWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listener.messageWantsDismissalCallCount, 1)
    }

    // MARK: - Private

    private lazy var fakeMessageWithListAndText: LocalizedTreatmentPerspective = {
        LocalizedTreatmentPerspective(paragraphs: [
            .init(title: "Paragraph Title",
                  body: NSAttributedString.htmlWithBulletList(text: "<b>Intro text</b>.\\n\\n<i>Second intro</i> and the text continue until it wraps around just check long lines.<ul><li>List Item 1 <b>bold</b></li><li>List Item 2 <i>italic</i></li></ul>\\nText below list", font: self.theme.fonts.body, textColor: self.theme.colors.gray, theme: self.theme, textAlignment: .left),
                  type: .paragraph),
            .init(title: "Paragraph Title",
                  body: NSAttributedString.htmlWithBulletList(text: "<b>Intro text</b>.\\n\\n<i>Second intro</i>.\n\n<ul><li>List Item 1</li><li>List Item 2</li></ul>\\nText below list", font: self.theme.fonts.body, textColor: self.theme.colors.gray, theme: self.theme, textAlignment: .left),
                  type: .paragraph)
        ])
    }()

    private lazy var fakeMessageWithListOnly: LocalizedTreatmentPerspective = {
        LocalizedTreatmentPerspective(paragraphs: [
            .init(title: "Paragraph Title",
                  body: NSAttributedString.htmlWithBulletList(text: "<ul><li>List Item 1</li><li>List Item 2</li></ul>", font: self.theme.fonts.body, textColor: self.theme.colors.gray, theme: self.theme, textAlignment: .left),
                  type: .paragraph),
            .init(title: "Paragraph 2 Title",
                  body: NSAttributedString.htmlWithBulletList(text: "<ul><li>List Item 1</li><li>List Item 2</li></ul>", font: self.theme.fonts.body, textColor: self.theme.colors.gray, theme: self.theme, textAlignment: .left),
                  type: .paragraph)
        ])
    }()

    private lazy var fakeMessageRTLWithList: LocalizedTreatmentPerspective = {
        LocalizedTreatmentPerspective(paragraphs: [
            .init(title: "هل أنت بحاجة الى مساعدة طبية؟",
                  body: NSAttributedString.htmlWithBulletList(text: "<ul><li>انتبه لصحتك دائمًا. هل لديك أعراض؟ ابق في المنزل إذًا واخضع للفحص مرة أخرى على الفور.</li><li>ابق لغاية بعيدًا عن الأشخاص ذوي الصحة الضعيفة أو الاشخاص الأكثر عرضة للخطر. تجنب الأماكن المزدحمة وابق على مسافة 1.5 متر. </li></ul>", font: self.theme.fonts.body, textColor: self.theme.colors.gray, theme: self.theme, textAlignment: .right),
                  type: .paragraph)
        ])
    }()

    private lazy var fakeMessageWithoutList: LocalizedTreatmentPerspective = {
        LocalizedTreatmentPerspective(paragraphs: [
            .init(title: "Paragraph Title",
                  body: NSAttributedString.htmlWithBulletList(text: "Some paragraph of text that is not followed by a list\\n\\nSome other paragraph of text", font: self.theme.fonts.body, textColor: self.theme.colors.gray, theme: self.theme, textAlignment: .left),
                  type: .paragraph),
            .init(title: "Paragraph Title",
                  body: NSAttributedString.htmlWithBulletList(text: "Some paragraph of text that is not followed by a list\\n\\nSome other paragraph of text", font: self.theme.fonts.body, textColor: self.theme.colors.gray, theme: self.theme, textAlignment: .left),
                  type: .paragraph)
        ])
    }()
}
