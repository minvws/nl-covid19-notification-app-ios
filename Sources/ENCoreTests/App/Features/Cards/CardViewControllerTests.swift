/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation

import Foundation
import XCTest

final class CardViewControllerTests: TestCase {
    private var viewController: CardViewController!
    private let mockRouter = CardRoutingMock()
    private var mockCardListener: CardListeningMock!
    private var mockExposureDataController: ExposureDataControllingMock!
    private var mockPauseController: PauseControllingMock!

    override func setUp() {
        super.setUp()

        recordSnapshots = false
        mockCardListener = CardListeningMock()
        mockExposureDataController = ExposureDataControllingMock()
        mockPauseController = PauseControllingMock()

        viewController = CardViewController(listener: mockCardListener,
                                            theme: theme,
                                            types: [.bluetoothOff],
                                            dataController: mockExposureDataController,
                                            pauseController: mockPauseController)
        viewController.router = mockRouter
    }

    func test_enableSettingRequestsDismiss_forwardsToRouter() {
        var hideViewController: Bool!
        mockRouter.detachEnableSettingHandler = { hideViewController = $0 }

        XCTAssertEqual(mockRouter.detachEnableSettingCallCount, 0)

        viewController.enableSettingRequestsDismiss(shouldDismissViewController: false)

        XCTAssertEqual(mockRouter.detachEnableSettingCallCount, 1)
        XCTAssertFalse(hideViewController)
    }

    func test_enableSettingDidTriggerAction_forwardsToRouter() {
        var hideViewController: Bool!
        mockRouter.detachEnableSettingHandler = { hideViewController = $0 }

        XCTAssertEqual(mockRouter.detachEnableSettingCallCount, 0)

        viewController.enableSettingDidTriggerAction()

        XCTAssertEqual(mockRouter.detachEnableSettingCallCount, 1)
        XCTAssertTrue(hideViewController)
    }

    func test_interopAnnouncement_primaryButton_shouldRouteToURL() throws {
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "en"

        viewController.update(cardTypes: [.interopAnnouncement])
        let stackView = try XCTUnwrap(viewController.view as? UIStackView)
        let cardView = try XCTUnwrap(stackView.arrangedSubviews.first as? CardView)

        let routingExpectation = expectation(description: "route")

        mockRouter.routeToHandler = { url in
            XCTAssertEqual(url, URL(string: "https://coronamelder.nl/en/operabiliteit")!)
            routingExpectation.fulfill()
        }

        cardView.primaryButton.action?()

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(mockRouter.routeToCallCount, 1)
    }

    func test_interopAnnouncement_shouldChangeURLBasedOnLanguageCode() throws {

        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "ar"

        viewController.update(cardTypes: [.interopAnnouncement])
        let stackView = try XCTUnwrap(viewController.view as? UIStackView)
        let cardView = try XCTUnwrap(stackView.arrangedSubviews.first as? CardView)

        let routingExpectation = expectation(description: "route")

        mockRouter.routeToHandler = { url in
            XCTAssertEqual(url, URL(string: "https://coronamelder.nl/ar/operabiliteit")!)
            routingExpectation.fulfill()
        }

        cardView.primaryButton.action?()

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_interopAnnouncement_shouldChooseSupportedLanguageCode() throws {

        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "blah" // unsupported language code on purpose

        viewController.update(cardTypes: [.interopAnnouncement])
        let stackView = try XCTUnwrap(viewController.view as? UIStackView)
        let cardView = try XCTUnwrap(stackView.arrangedSubviews.first as? CardView)

        let routingExpectation = expectation(description: "route")

        mockRouter.routeToHandler = { url in
            XCTAssertEqual(url, URL(string: "https://coronamelder.nl/en/operabiliteit")!)
            routingExpectation.fulfill()
        }

        cardView.primaryButton.action?()

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_interopAnnouncement_secondaryButton_shouldDismissAnnouncementAndCallListener() throws {
        viewController.update(cardTypes: [.interopAnnouncement])
        let stackView = try XCTUnwrap(viewController.view as? UIStackView)
        let cardView = try XCTUnwrap(stackView.arrangedSubviews.first as? CardView)

        XCTAssertEqual(mockRouter.routeToCallCount, 0)
        XCTAssertEqual(mockExposureDataController.seenAnnouncementsSetCallCount, 0)

        let listenerExpectation = expectation(description: "route")
        mockCardListener.dismissedAnnouncementHandler = {
            listenerExpectation.fulfill()
        }

        cardView.secondaryButton.action?()

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(mockExposureDataController.seenAnnouncementsSetCallCount, 1)
        XCTAssertEqual(mockExposureDataController.seenAnnouncements, [.interopAnnouncement])
    }
}
