/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
import RxSwift
@testable import ENCore

class NetworkStatusStreamTests: TestCase {

    private var sut: NetworkStatusStream!
    private var mockReachabilityProvider: ReachabilityProvidingMock!
    
    private var disposeBag = DisposeBag()
    
    override func setUpWithError() throws {
        mockReachabilityProvider = ReachabilityProvidingMock()
        
        sut = NetworkStatusStream(reachabilityProvider: mockReachabilityProvider)
    }

    func test_startObservingNetworkReachability() {
        // Arrange
        let reachabilityMock = ReachabilityProtocolMock()
        mockReachabilityProvider.getReachabilityHandler = {
            reachabilityMock
        }
        
        XCTAssertEqual(mockReachabilityProvider.getReachabilityCallCount, 0)
        XCTAssertEqual(reachabilityMock.setNetworkAvailabilityChangeHandlerCallCount, 0)
        XCTAssertEqual(reachabilityMock.startNotifierCallCount, 0)
        
        // Act
        sut.startObservingNetworkReachability()
        
        // Assert
        XCTAssertEqual(mockReachabilityProvider.getReachabilityCallCount, 1)
        XCTAssertEqual(reachabilityMock.setNetworkAvailabilityChangeHandlerCallCount, 1)
        XCTAssertEqual(reachabilityMock.startNotifierCallCount, 1)
    }
    
    func test_networkAvailabilityChange_shouldUpdateSubject() {
        // Arrange
        var setHandler: ((Bool) -> Void)?
        _ = startReachability { (handler) in
            setHandler = handler
        }
        
        XCTAssertFalse(sut.networkReachable)
        
        // Act
        setHandler?(true)
        
        // Assert
        XCTAssertTrue(sut.networkReachable)
    }
    
    func test_networkAvailabilityChange_shouldOnlyTriggerDistinctStreamChanges() {
        // Arrange
        var setHandler: ((Bool) -> Void)?
        _ = startReachability { (handler) in
            setHandler = handler
        }
        let subscriptionExpectation = expectation(description: "subscriptionExpectation")
        subscriptionExpectation.expectedFulfillmentCount = 2
        
        XCTAssertFalse(sut.networkReachable)
        
        sut.networkReachableStream
            .subscribe(onNext: { available in
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Act
        setHandler?(false)
        setHandler?(false)
        setHandler?(true)
        setHandler?(true)
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(sut.networkReachable)
    }
    
    func test_stopObservingNetworkReachability() {
        // Arrange
        let reachabilityMock = startReachability(handler: nil)
        XCTAssertEqual(reachabilityMock.stopNotifierCallCount, 0)
        
        // Act
        sut.stopObservingNetworkReachability()
        
        // Assert
        XCTAssertEqual(reachabilityMock.stopNotifierCallCount, 1)
    }
    
    // MARK: - Private Helper Functions
    
    private func startReachability(handler: ((@escaping (_ networkAvailable: Bool) -> Void) -> ())?) -> ReachabilityProtocolMock {
        let reachabilityMock = ReachabilityProtocolMock()
        mockReachabilityProvider.getReachabilityHandler = {
            reachabilityMock
        }
        
        reachabilityMock.setNetworkAvailabilityChangeHandlerHandler = handler
        
        sut.startObservingNetworkReachability()
        return reachabilityMock
    }
    
}
