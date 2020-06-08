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
        onboardingBuilder.buildHandler = { _ in return OnboardingViewControllableMock() }
        
        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        
        router.start()
        
        XCTAssertEqual(onboardingBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 1)
    }
    
    func test_callStartTwice_doesNotPresentTwice() {
        onboardingBuilder.buildHandler = { _ in OnboardingViewControllableMock() }
        
        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        
        router.start()
        router.start()
        
        XCTAssertEqual(onboardingBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 1)
    }
    
    func test_detachOnboarding_whenOnboardingNotPresented_doesNotCallDismiss() {
        XCTAssertEqual(viewController.dismissCallCount, 0)
        
        var completionCalled = false
        router.detachOnboarding(animated: true, completion: { completionCalled = true })
        
        XCTAssertEqual(viewController.dismissCallCount, 0)
        XCTAssertTrue(completionCalled)
    }
    
    func test_detachOnboarding_whenOnboardingPresented_callsDismiss() {
        router.start()
        viewController.dismissHandler = { _, _, completion in completion?() }
        
        XCTAssertEqual(viewController.dismissCallCount, 0)
        
        var completionCalled = false
        router.detachOnboarding(animated: true, completion: { completionCalled = true })
        
        XCTAssertEqual(viewController.dismissCallCount, 1)
        XCTAssertTrue(completionCalled)
    }
    
    func test_routeToMain_presentsMain() {
        mainBuilder.buildHandler = { MainViewControllableMock() }
        
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        
        router.routeToMain()
        
        XCTAssertEqual(mainBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 1)
    }
}
