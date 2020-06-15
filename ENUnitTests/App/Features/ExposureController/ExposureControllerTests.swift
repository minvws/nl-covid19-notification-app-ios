/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import EN
import Foundation
import XCTest

final class ExposureControllerTests: XCTestCase {
    private var controller: ExposureController!
    private let mutableStatusStream = MutableExposureStateStreamingMock()
    private let exposureManager = ExposureManagingMock()
    
    override func setUp() {
        super.setUp()
        
        controller = ExposureController(mutableStatusStream: mutableStatusStream,
                                        exposureManager: exposureManager)
        
        exposureManager.activateCallCount = 0
        mutableStatusStream.updateCallCount = 0
    }
    
    func test_activate_activesAndUpdatesStream() {
        exposureManager.activateHandler = { completion in completion(.active) }
        exposureManager.getExposureNotificationStatusHandler = { .active }
        
        XCTAssertEqual(exposureManager.activateCallCount, 0)
        XCTAssertEqual(mutableStatusStream.updateCallCount, 0)
        
        controller.activate()
        
        XCTAssertEqual(exposureManager.activateCallCount, 1)
        XCTAssertEqual(mutableStatusStream.updateCallCount, 1)
    }
    
    func test_requestExposureNotificationPermission_callsManager_updatesStream() {
        var receivedEnabled: Bool!
        exposureManager.setExposureNotificationEnabledHandler = { enabled, completion in
            receivedEnabled = enabled
            
            completion(.success(()))
        }
        
        exposureManager.getExposureNotificationStatusHandler = { .active }
        
        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 0)
        XCTAssertEqual(mutableStatusStream.updateCallCount, 0)
        
        controller.requestExposureNotificationPermission()
        
        XCTAssertEqual(mutableStatusStream.updateCallCount, 1)
        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 1)
        XCTAssertNotNil(receivedEnabled)
        XCTAssertTrue(receivedEnabled)
    }
    
    func test_requestPushNotificationPermission() {
        // Not implemented yet
    }
    
    func test_confirmExposureNotification() {
        // Not implemented yet
    }
    
    func test_activate_noManager_updatesStreamWithRequiresOSUpdate() {
        exposureManager.activateHandler = { completion in completion(.active) }
        
        let expectation = expect(activeState: .inactive(.requiresOSUpdate))
        
        controller = ExposureController(mutableStatusStream: mutableStatusStream, exposureManager: nil)
        controller.activate()
        
        XCTAssertTrue(expectation.evaluate())
    }
    
    func test_managerIsActive_updatesStreamWithActive() {
        exposureManager.getExposureNotificationStatusHandler = { .active }
        
        let expectation = expect(activeState: .active)
        
        triggerUpdateStream()
        
        XCTAssertTrue(expectation.evaluate())
    }
    
    func test_managerIsInactiveBecauseBluetoothOff_updatesStreamWithInactiveBluetoothOff() {
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.bluetoothOff) }
        
        let expectation = expect(activeState: .inactive(.bluetoothOff))
        
        triggerUpdateStream()
        
        XCTAssertTrue(expectation.evaluate())
    }
    
    func test_managerIsInactiveBecauseDisabled_updatesStreamWithInactiveDisabled() {
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.disabled) }
        
        let expectation = expect(activeState: .inactive(.disabled))
        
        triggerUpdateStream()
        
        XCTAssertTrue(expectation.evaluate())
    }
    
    func test_managerIsInactiveBecauseRestricted_updatesStreamWithInactiveDisabled() {
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.restricted) }
        
        let expectation = expect(activeState: .inactive(.disabled))
        
        triggerUpdateStream()
        
        XCTAssertTrue(expectation.evaluate())
    }
    
    func test_managerIsInactiveBecauseNotAuthorized_updatesStreamWithNotAuthorized() {
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.notAuthorized) }
        
        let expectation = expect(activeState: .notAuthorized)
        
        triggerUpdateStream()
        
        XCTAssertTrue(expectation.evaluate())
    }
    
    func test_managerIsInactiveBecauseUnknown_updatesStreamWithDisabled() {
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.unknown) }
        
        let expectation = expect(activeState: .inactive(.disabled))
        
        triggerUpdateStream()
        
        XCTAssertTrue(expectation.evaluate())
    }
    
    func test_managerIsNotAuthorized_updatesStreamWithNotAuthorized() {
        exposureManager.getExposureNotificationStatusHandler = { .notAuthorized }
        
        let expectation = expect(activeState: .notAuthorized)
        
        triggerUpdateStream()
        
        XCTAssertTrue(expectation.evaluate())
    }
    
    // MARK: - Private
    
    private func triggerUpdateStream() {
        // trigger status update by mocking enabling notifications
        exposureManager.setExposureNotificationEnabledHandler = { _, completion in completion(.success(())) }
        
        controller.requestExposureNotificationPermission()
    }
    
    private func expect(activeState: ExposureActiveState? = nil, notified: Bool? = nil) -> ExpectStatusEvaluator {
        let evaluator = ExpectStatusEvaluator(activeState: activeState, notified: notified)
        
        mutableStatusStream.updateHandler = evaluator.updateHandler
        
        return evaluator
    }
    
    private final class ExpectStatusEvaluator {
        private let expectedActiveState: ExposureActiveState?
        private let expectedNotified: Bool?
        
        private var receivedState: ExposureState?
        
        init(activeState: ExposureActiveState?, notified: Bool?) {
            expectedActiveState = activeState
            expectedNotified = notified
        }
        
        var updateHandler: (ExposureState) -> () {
            return { [weak self] state in
                self?.receivedState = state
            }
        }
        
        func evaluate() -> Bool {
            guard let state = receivedState else { return false }
            
            var matchActiveState = true
            var matchNotified = true
            
            if let activeState = expectedActiveState {
                matchActiveState = activeState == state.activeState
            }
            
            if let notified = expectedNotified {
                matchNotified = notified == state.notified
            }
            
            return matchActiveState && matchNotified
        }
    }
}
