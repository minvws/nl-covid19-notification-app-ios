/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift

/// @mockable
protocol NetworkStatusStreaming {
    var networkReachable: Bool { get }
    var networkReachableStream: Observable<Bool> { get }
}

/// @mockable
protocol MutableNetworkStatusStreaming: NetworkStatusStreaming {
    func startObservingNetworkReachability()
    func stopObservingNetworkReachability()
}

final class NetworkStatusStream: MutableNetworkStatusStreaming, Logging {

    init(reachabilityProvider: ReachabilityProviding) {
        self.reachabilityProvider = reachabilityProvider
    }
    // MARK: - PushNotificationStreaming

    var networkReachable: Bool {
        return (try? subject.value()) ?? false
    }

    var networkReachableStream: Observable<Bool> {
        return subject
            .distinctUntilChanged()
            .share()
    }

    // MARK: - MutablePushNotificationStreaming

    func startObservingNetworkReachability() {
        if self.reachability == nil, let reachability = reachabilityProvider.getReachability() {
            self.reachability = reachability
        }
        
        reachability?.setNetworkAvailabilityChangeHandler(handler: { [weak self] (networkAvailable) in
            self?.subject.onNext(networkAvailable)
        })

        do {
            try reachability?.startNotifier()
        } catch {
            logError("Unable to start Reachability")
        }
    }

    func stopObservingNetworkReachability() {
        guard let reachability = reachability else {
            return
        }
        reachability.stopNotifier()
    }

    private func update(isReachable: Bool) {
        subject.onNext(isReachable)
    }

    private let subject = BehaviorSubject<Bool>(value: false)
    private let reachabilityProvider: ReachabilityProviding
    private var reachability: ReachabilityProtocol?
}
