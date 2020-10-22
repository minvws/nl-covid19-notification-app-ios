/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation
import UIKit

/// @mockable
protocol DeviceOrientationStreaming {
    var isLandscape: AnyPublisher<Bool, Never> { get }
    var currentOrientationIsLandscape: Bool? { get }
}

final class DeviceOrientationStream: DeviceOrientationStreaming {

    init() {
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.currentOrientationIsLandscape = UIDevice.current.orientation.isLandscape
            self?.subject.send(UIDevice.current.orientation.isLandscape)
        }
    }

    // MARK: - DeviceOrientationStreaming

    var isLandscape: AnyPublisher<Bool, Never> {
        return subject
            .removeDuplicates(by: ==)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var currentOrientationIsLandscape: Bool?
    private let subject = CurrentValueSubject<Bool?, Never>(nil)
}
