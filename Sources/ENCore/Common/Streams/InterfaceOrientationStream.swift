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
protocol InterfaceOrientationStreaming {
    var isLandscape: AnyPublisher<Bool, Never> { get }
    var currentOrientationIsLandscape: Bool? { get }
}

final class InterfaceOrientationStream: InterfaceOrientationStreaming {

    init() {

        updateSubject()

        // We listen for device orientation changes (which are more sensitive)
        // but we use the interface orientation of the key window to actually determine the rotation of the UI
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateSubject()
        }
    }

    private func updateSubject() {
        guard let windowScene = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene else {
            return
        }

        currentOrientationIsLandscape = windowScene.interfaceOrientation.isLandscape
        subject.send(windowScene.interfaceOrientation.isLandscape)
    }

    // MARK: - InterfaceOrientationStreaming

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
