/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

struct ExposureState: Equatable {
    let notifiedState: ExposureNotificationState
    let activeState: ExposureActiveState
}

enum ExposureNotificationState: Equatable {
    case notified(Date)
    case notNotified
}

enum ExposureActiveState: Equatable {
    /// Exposure Notification is active
    case active

    /// Exposure Notification is restricted
    case restricted

    /// Exposure Notification is inactive, inactiveState contains the reason why
    case inactive(ExposureStateInactiveState)

    /// No authorisation has been given yet
    case notAuthorized

    /// Authorisation has been explicitly denied
    case authorizationDenied
}

enum ExposureStateInactiveState: Equatable {
    case disabled
    case bluetoothOff
    case pushNotifications
    case noRecentNotificationUpdates
    case noRecentNotificationUpdatesInternetOff
    case paused(_ endDate: Date)
}

/// @mockable
protocol ExposureStateStreaming {
    /// An observable to subscribe to for getting new state updates
    /// Does not emit the current state immediately
    var exposureState: Observable<ExposureState> { get }

    /// Returns the last state, if any was set
    var currentExposureState: ExposureState { get }
}

/// @mockable(history: update = true)
protocol MutableExposureStateStreaming: ExposureStateStreaming {
    func update(state: ExposureState)
}

/// This stream drives a lot of functionality of the app. It emits a state that encapsulates information about wether or not the user has been notified (exposed)
/// as well as the state of framework itself (enabled / disabled / bluetooth is off etc.). This state is not only shown to the user on the main screen of the app
/// but also determines wether we can check for exposures in the background process.
final class ExposureStateStream: MutableExposureStateStreaming {

    // MARK: - ExposureStateStreaming

    var exposureState: Observable<ExposureState> {
        subject
            .distinctUntilChanged()
            .compactMap { $0 }
    }

    var currentExposureState: ExposureState = .init(notifiedState: .notNotified, activeState: .notAuthorized)

    // MARK: - MutableExposureStateStreaming

    func update(state: ExposureState) {
        currentExposureState = state

        subject.onNext(state)
    }

    // MARK: - Private

    private var subject = BehaviorSubject<ExposureState?>(value: .init(notifiedState: .notNotified, activeState: .notAuthorized))
}
