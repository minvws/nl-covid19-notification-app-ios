/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest
import ENFoundation

class ShareKeyViaWebsiteRouterTests: TestCase {
    
    private var sut: ShareKeyViaWebsiteRouter!
    
    private var mockListener: ShareKeyViaWebsiteListenerMock!
    private var mockViewController: ShareKeyViaWebsiteViewControllableMock!
    private var mockThankYouBuilder: ThankYouBuildableMock!
    private var mockCardBuilder: CardBuildableMock!
    private var mockHelpDetailBuilder: HelpDetailBuildableMock!
    private var mockAlertControllerBuilder: AlertControllerBuildableMock!
    
    override func setUp() {
        super.setUp()
        
        mockListener = ShareKeyViaWebsiteListenerMock()
        mockViewController = ShareKeyViaWebsiteViewControllableMock()
        mockThankYouBuilder = ThankYouBuildableMock()
        mockCardBuilder = CardBuildableMock()
        mockHelpDetailBuilder = HelpDetailBuildableMock()
        mockAlertControllerBuilder = AlertControllerBuildableMock()
        
        sut = ShareKeyViaWebsiteRouter(
            listener: mockListener,
            viewController: mockViewController,
            thankYouBuilder: mockThankYouBuilder,
            cardBuilder: mockCardBuilder,
            helpDetailBuilder: mockHelpDetailBuilder,
            alertControllerBuilder: mockAlertControllerBuilder
        )
    }
    
    func test_shareKeyViaWebsiteWantsDismissal_shouldcallListener() {
        // Arrange
        XCTAssertEqual(mockListener.shareKeyViaWebsiteWantsDismissalCallCount, 0)
        
        // Act
        sut.shareKeyViaWebsiteWantsDismissal(shouldDismissViewController: true)
        
        // Assert
        XCTAssertEqual(mockListener.shareKeyViaWebsiteWantsDismissalCallCount, 1)
        XCTAssertTrue(mockListener.shareKeyViaWebsiteWantsDismissalArgValues.first!)
    }
    
    func test_didCompleteScreen_shouldShowAlert() {
        // Arrange
        XCTAssertEqual(mockViewController.presentCallCount, 0)
        
        var presentedAlertController: UIAlertController!
        mockAlertControllerBuilder.buildAlertControllerHandler = { title, message, style in
            XCTAssertEqual(title, .moreInformationKeySharingCoronaTestCompleteTitle)
            XCTAssertEqual(message, .moreInformationKeySharingCoronaTestCompleteContent)
            XCTAssertEqual(style, .alert)
            presentedAlertController = UIAlertController(title: title, message: message, preferredStyle: style)
            return presentedAlertController
        }
        
        mockAlertControllerBuilder.buildAlertActionHandler = { title, style, action in
            if style == .cancel {
                XCTAssertEqual(title, .moreInformationKeySharingCoronaTestCompleteCancel)
            } else {
                XCTAssertEqual(title, .moreInformationKeySharingCoronaTestCompleteOK)
            }
            return UIAlertAction(title: title, style: style, handler: action)
        }
        
        // Act
        sut.didCompleteScreen(withKey: getFakeLabConfirmationKey())
        
        // Assert
        XCTAssertTrue(mockViewController.presentArgValues.first?.0 === presentedAlertController)
        XCTAssertEqual(mockViewController.presentCallCount, 1)
    }
    
    func test_didCompleteScreen_shouldRouteToThankYouAfterSelectingAlertAction() {
        // Arrange
        XCTAssertEqual(mockViewController.pushCallCount, 0)
        
        var confirmActionHandler: ((UIAlertAction) -> Void)!
        var confirmAction: UIAlertAction!
        mockAlertControllerBuilder.buildAlertControllerHandler = { title, message, style in
            return UIAlertController(title: title, message: message, preferredStyle: style)
        }
        
        mockAlertControllerBuilder.buildAlertActionHandler = { title, style, action in
            if style == .default {
                confirmActionHandler = action
            }
            confirmAction = UIAlertAction(title: title, style: style, handler: action)
            return confirmAction
        }
        
        var thankYouViewControllable: ViewControllableMock!
        mockThankYouBuilder.buildHandler = { _, _ in
            thankYouViewControllable = ViewControllableMock()
            return thankYouViewControllable
        }
        
        // Act
        sut.didCompleteScreen(withKey: getFakeLabConfirmationKey())
        confirmActionHandler(confirmAction)
        
        // Assert
        XCTAssertEqual(mockViewController.pushCallCount, 1)
        XCTAssertTrue(mockViewController.pushArgValues.first === thankYouViewControllable)
    }
    
    func test_showInactiveCard_shouldSetCardOnViewController() {
        // Arrange
        let cardRouter = CardRouterMock()
        cardRouter.viewControllable = ViewControllableMock()
        
        mockCardBuilder.buildHandler = { listener, types in
            XCTAssertEqual(types, [.exposureOff])
            return cardRouter
        }
        
        // Act
        sut.showInactiveCard(state: .authorizationDenied)
        
        // Assert
        XCTAssertTrue(mockViewController.setArgValues.first! === cardRouter.viewControllable)
    }
    
    func test_showInactiveCard_shouldSetCardOnViewController_notAuthorized() {
        // Arrange
        let cardRouter = CardRouterMock()
        cardRouter.viewControllable = ViewControllableMock()
        
        mockCardBuilder.buildHandler = { listener, types in
            XCTAssertEqual(types, [.notAuthorized])
            return cardRouter
        }
        
        // Act
        sut.showInactiveCard(state: .notAuthorized)
        
        // Assert
        XCTAssertTrue(mockViewController.setArgValues.first! === cardRouter.viewControllable)
    }
    
    func test_removeInactiveCard() {
        // Arrange
        XCTAssertEqual(mockViewController.setCallCount, 0)
        
        let cardRouter = CardRouterMock()
        cardRouter.viewControllable = ViewControllableMock()
        
        mockCardBuilder.buildHandler = { listener, types in
            return cardRouter
        }
        
        // Act
        sut.showInactiveCard(state: .authorizationDenied)
        sut.removeInactiveCard()
        
        // Assert
        XCTAssertEqual(mockViewController.setCallCount, 2)
        XCTAssertNil(mockViewController.setArgValues[1])
    }
    
    func test_showFAQ() {
        // Arrange
        XCTAssertEqual(mockViewController.presentInNavigationControllerCallCount, 0)
        let viewControllable = ViewControllableMock()
        mockHelpDetailBuilder.buildHandler = { listener, shouldShowEnableAppButton, entry in
            XCTAssertTrue(listener === self.mockViewController)
            XCTAssertFalse(shouldShowEnableAppButton)
            
            XCTAssertEqual(entry.title, .helpFaqUploadKeysTitle)
            XCTAssertEqual(entry.answer, .helpFaqUploadKeysDescription)
            return viewControllable
        }
        
        // Act
        sut.showFAQ()
        
        // Assert
        XCTAssertEqual(mockViewController.presentInNavigationControllerCallCount, 1)
        XCTAssertTrue(mockViewController.presentInNavigationControllerArgValues.first === viewControllable)
    }
    
    func test_hideFAQ() {
        // Arrange
        XCTAssertEqual(mockViewController.dismissCallCount, 0)
        let viewControllable = ViewControllableMock()
        mockHelpDetailBuilder.buildHandler = { listener, shouldShowEnableAppButton, entry in
            return viewControllable
        }
        
        // Act
        sut.showFAQ()
        sut.hideFAQ(shouldDismissViewController: true)
        
        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 1)
        XCTAssertTrue(mockViewController.dismissArgValues.first === viewControllable)
    }
    
    // MARK: - Private Helpers
    
    private func getFakeLabConfirmationKey() -> LabConfirmationKey {
        LabConfirmationKey(identifier: "key here",
                           bucketIdentifier: Data(),
                           confirmationKey: Data(),
                           validUntil: currentDate())
    }
}

fileprivate class CardRouterMock: RoutingMock & CardTypeSettable {
    var types: [CardType] = []
}
