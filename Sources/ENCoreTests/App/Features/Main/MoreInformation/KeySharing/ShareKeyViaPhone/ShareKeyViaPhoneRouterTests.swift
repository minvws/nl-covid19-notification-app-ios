/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class ShareKeyViaPhoneRouterTests: TestCase {
    
    private var mockListener: ShareKeyViaPhoneListenerMock!
    private var mockViewController: ShareKeyViaPhoneViewControllableMock!
    private var mockThankYouBuilder: ThankYouBuildableMock!
    private var mockCardBuilder: CardBuildableMock!
    private var mockHelpDetailBuilder: HelpDetailBuildableMock!
    
    private var sut: ShareKeyViaPhoneRouter!
    
    override func setUp() {
        super.setUp()

        mockListener = ShareKeyViaPhoneListenerMock()
        mockViewController = ShareKeyViaPhoneViewControllableMock()
        mockThankYouBuilder = ThankYouBuildableMock()
        mockCardBuilder = CardBuildableMock()
        mockHelpDetailBuilder = HelpDetailBuildableMock()
        
        sut = ShareKeyViaPhoneRouter(listener: mockListener,
                                     viewController: mockViewController,
                                     thankYouBuilder: mockThankYouBuilder,
                                     cardBuilder: mockCardBuilder,
                                     helpDetailBuilder: mockHelpDetailBuilder)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(mockViewController.routerSetCallCount, 1)
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
}

fileprivate class CardRouterMock: RoutingMock & CardTypeSettable {
    var types: [CardType] = []
}
