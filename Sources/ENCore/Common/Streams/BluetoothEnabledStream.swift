/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

/// @mockable
protocol BluetoothStateStreaming {
    var enabled: AnyPublisher<Bool, Never> { get }
}

/// @mockable
protocol MutableBluetoothStateStreaming: BluetoothStateStreaming {
    func update(enabled: Bool)
}

final class BluetoothStateStream: MutableBluetoothStateStreaming {

    // MARK: - ExposureStateStreaming

    var enabled: AnyPublisher<Bool, Never> {
        return subject
            .removeDuplicates(by: ==)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - MutableExposureStateStreaming

    func update(enabled: Bool) {
        subject.send(enabled)
    }

    // MARK: - Private

    private let subject = CurrentValueSubject<Bool?, Never>(nil)
}
