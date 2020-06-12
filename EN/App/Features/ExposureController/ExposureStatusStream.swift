//
//  ExposureStatusStream.swift
//  EN
//
//  Created by Robin van Dijke on 12/06/2020.
//

import Combine
import Foundation

enum ExposureState: Equatable {
    case active
    case notified
    case inactive(ExposureStateInactiveState)
}

enum ExposureStateInactiveState: Equatable {
    case paused
    case disabled
    case requiresOSUpdate
    case notAuthorized
    case bluetoothOff
    case noRecentNotificationUpdates
}

protocol ExposureStateStreaming {
    var exposureStatus: AnyPublisher<ExposureState, Never> { get }
}

protocol MutableExposureStateStreaming: ExposureStateStreaming {
    func update(state: ExposureState)
}

final class ExposureStateStream: MutableExposureStateStreaming {
    let subject = PassthroughSubject<ExposureState, Never>()
    
    // MARK: - ExposureStateStreaming
    
    var exposureStatus: AnyPublisher<ExposureState, Never> {
        return subject.removeDuplicates(by: ==).eraseToAnyPublisher()
    }
    
    // MARK: - MutableExposureStateStreaming
    
    func update(state: ExposureState) {
        subject.send(state)
    }
}
