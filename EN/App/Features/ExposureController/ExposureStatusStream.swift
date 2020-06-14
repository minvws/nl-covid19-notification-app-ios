/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Combine
import Foundation

struct ExposureState: Equatable {
    let notified: Bool
    let activeState: ExposureActiveState
}

enum ExposureActiveState: Equatable {
    case active
    case inactive(ExposureStateInactiveState)
    case notAuthorized
}

enum ExposureStateInactiveState: Equatable {
    case paused
    case disabled
    case requiresOSUpdate
    case bluetoothOff
    case noRecentNotificationUpdates
}

protocol ExposureStateStreaming {
    /// A publisher to subscribe to for getting new state updates
    /// Does not emit the current state immediately
    var exposureState: AnyPublisher<ExposureState, Never> { get }
    
    /// Returns the last state, if any was set
    var currentExposureState: ExposureState? { get }
}

protocol MutableExposureStateStreaming: ExposureStateStreaming {
    func update(state: ExposureState)
}

final class ExposureStateStream: MutableExposureStateStreaming {
    let subject = PassthroughSubject<ExposureState, Never>()
    
    // MARK: - ExposureStateStreaming
    
    var exposureState: AnyPublisher<ExposureState, Never> {
        return subject.removeDuplicates(by: ==).eraseToAnyPublisher()
    }
    
    var currentExposureState: ExposureState?
    
    // MARK: - MutableExposureStateStreaming
    
    func update(state: ExposureState) {
        currentExposureState = state
        
        subject.send(state)
    }
}
