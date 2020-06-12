//
//  ExposureController.swift
//  EN
//
//  Created by Robin van Dijke on 12/06/2020.
//

import Foundation

final class ExposureController: ExposureControlling {
    init(mutableStatusStream: MutableExposureStateStreaming,
         exposureManager: ExposureManaging?) {
        self.mutableStatusStream = mutableStatusStream
        self.exposureManager = exposureManager
        
        activateExposureManager()
        updateStatusStream()
    }
    
    // MARK: - ExposureControlling
    
    func requestExposureNotificationPermission() {
        exposureManager?.setExposureNotificationEnabled(true) { _ in
            self.updateStatusStream()
        }
    }
    
    func requestPushNotificationPermission() {
        // Not implemented yet
    }
    
    func confirmExposureNotification() {
        // Not implemented yet
    }
    
    // MARK: - Private
    
    func activateExposureManager() {
        exposureManager?.activate { _ in
            self.updateStatusStream()
        }
    }
    
    func updateStatusStream() {
        guard let exposureManager = exposureManager else {
            mutableStatusStream.update(state: .inactive(.requiresOSUpdate))
            
            return
        }
        
        let state: ExposureState
        
        switch exposureManager.getExposureNotificationAuthorisationStatus() {
        case .active:
            state = .active
        case .inactive(let error) where error == .bluetoothOff:
            state = .inactive(.bluetoothOff)
        case .inactive(let error) where error == .disabled || error == .restricted:
            state = .inactive(.disabled)
        case .inactive(let error) where error == .notAuthorized:
            state = .inactive(.notAuthorized)
        case .inactive(_):
            state = .inactive(.disabled)
        }
        
        mutableStatusStream.update(state: state)
    }
    
    private let mutableStatusStream: MutableExposureStateStreaming
    private let exposureManager: ExposureManaging?
}
