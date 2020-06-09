/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

@testable import EN
import Foundation
import XCTest

final class RootRouterTests: XCTestCase {
    private let viewController = RootViewControllableMock()
    private let onboardingBuilder = OnboardingBuildableMock()
    private let mainBuilder = MainBuildableMock()
    
    private var router: RootRouter!
    
    override func setUp() {
        super.setUp()
        
        router = RootRouter(viewController: viewController,
                                onboardingBuilder: onboardingBuilder,
                                mainBuilder: mainBuilder)
    }
    
    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }
    
    func test_start_buildsAndPresentsOnboarding() {
        onboardingBuilder.buildHandler = { _ in return OnboardingRoutingMock() }
        
        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        
        router.start()
        
        XCTAssertEqual(onboardingBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 1)
    }
    
    func test_callStartTwice_doesNotPresentTwice() {
        onboardingBuilder.buildHandler = { _ in OnboardingRoutingMock() }
        
        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        
        router.start()
        router.start()
        
        XCTAssertEqual(onboardingBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 1)
    }
    
    func test_detachOnboardingAndRouteToMain_callsEmbedAndDismiss() {
        router.start()
        
        XCTAssertEqual(viewController.embedCallCount, 0)
        XCTAssertEqual(viewController.dismissCallCount, 0)
        
        router.detachOnboardingAndRouteToMain(animated: true)
        
        XCTAssertEqual(viewController.embedCallCount, 1)
        XCTAssertEqual(viewController.dismissCallCount, 1)
    }
}
