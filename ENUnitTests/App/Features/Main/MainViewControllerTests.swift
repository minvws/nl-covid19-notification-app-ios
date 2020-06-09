/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

@testable import EN
import Foundation
import XCTest

final class MainViewControllerTests: XCTestCase {
    private var viewController: MainViewController!
    private let statusBuilder = StatusBuildableMock()
    private let moreInformationBuilder = MoreInformationBuildableMock()
    
    override func setUp() {
        super.setUp()
        
        viewController = MainViewController(statusBuilder: statusBuilder,
                                            moreInformationBuilder: moreInformationBuilder)
    }
    
    func test_attachStatus_callsBuildAndEmbeds() {
        var receivedListener: Any?
        statusBuilder.buildHandler = { listener in
            receivedListener = listener
            
            return StatusRoutingMock()
        }
        
        XCTAssertEqual(statusBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.children.count, 0)
        
        viewController.attachStatus()
        
        XCTAssertEqual(statusBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.children.count, 1)
        XCTAssertTrue(receivedListener is MainViewControllable)
        XCTAssertTrue((receivedListener as! MainViewControllable) === viewController)
    }
    
    func test_attachMoreInformation_callsBuildAndEmbeds() {
        var receivedListener: Any?
        moreInformationBuilder.buildHandler = { listener in
            receivedListener = listener
            
            return MoreInformationRoutingMock()
        }
        
        XCTAssertEqual(moreInformationBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.children.count, 0)
        
        viewController.attachMoreInformation()
        
        XCTAssertEqual(moreInformationBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.children.count, 1)
        XCTAssertTrue(receivedListener is MainViewControllable)
        XCTAssertTrue((receivedListener as! MainViewControllable) === viewController)
    }
    
    func test_viewDidLoad_buildsStatusAndMoreInformation_inRightOrder() {
        statusBuilder.buildHandler = { _ in
            return StatusRoutingMock(viewControllable: StatusViewController())
        }
        
        moreInformationBuilder.buildHandler = { _ in
            return MoreInformationRoutingMock(viewControllable: MoreInformationViewController())
        }
        
        XCTAssertEqual(statusBuilder.buildCallCount, 0)
        XCTAssertEqual(moreInformationBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.children.count, 0)
        
        // cause loadView/viewDidLoad cycle
        _ = viewController.view
        
        XCTAssertEqual(statusBuilder.buildCallCount, 1)
        XCTAssertEqual(moreInformationBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.children.count, 2)
        XCTAssertTrue(viewController.children[0] is StatusViewControllable)
        XCTAssertTrue(viewController.children[1] is MoreInformationViewControllable)
    }
}
