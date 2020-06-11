/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

@testable import EN
import Foundation
import XCTest

final class WebViewControllerTests: XCTestCase {
    private var viewController: WebViewController!
    private let listener = WebListenerMock()
    private let webView = WebViewingMock()
    
    override func setUp() {
        super.setUp()
        
        let request = URLRequest(url: URL(string: "https://www.rijksoverheid.nl")!)
        viewController = WebViewController(listener: listener,
                                           webView: webView,
                                           urlRequest: request)
    }
    
    func test_didMoveToParentViewController_validParent_callsLoadRequest() {
        XCTAssertEqual(webView.loadCallCount, 0)
        
        viewController.didMove(toParent: UIViewController())
        
        XCTAssertEqual(webView.loadCallCount, 1)
    }
    
    func test_didMoveToParentViewController_nilParent_doesNotCallLoadRequest() {
        XCTAssertEqual(webView.loadCallCount, 0)
        
        viewController.didMove(toParent: nil)
        
        XCTAssertEqual(webView.loadCallCount, 0)
    }
}
