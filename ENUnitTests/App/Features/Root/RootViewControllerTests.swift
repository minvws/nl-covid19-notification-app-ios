//
//  RootViewControllerTests.swift
//  ENUnitTests
//
//  Created by Robin van Dijke on 09/06/2020.
//  Copyright © 2020 Rob Mulder. All rights reserved.
//

@testable import EN
import Foundation
import XCTest

final class RootViewControllerTests: XCTestCase {
    private var viewController: RootViewController!
    private let router = RootRoutingMock()
    
    override func setUp() {
        super.setUp()
        
        viewController = RootViewController()
        viewController.router = router
    }
    
    func test_didCompleteOnboarding_callsDetachOnboardingAndRoutesToMain() {
        router.detachOnboardingHandler = { _, completion in completion() }
        
        XCTAssertEqual(router.detachOnboardingCallCount, 0)
        XCTAssertEqual(router.routeToMainCallCount, 0)
        
        viewController.didCompleteOnboarding()
        
        XCTAssertEqual(router.detachOnboardingCallCount, 1)
        XCTAssertEqual(router.routeToMainCallCount, 1)
    }
}
