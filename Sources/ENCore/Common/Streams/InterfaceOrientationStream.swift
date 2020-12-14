/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift
import UIKit

/// @mockable
protocol InterfaceOrientationStreaming {
    var isLandscape: PublishSubject<Bool> { get }
    var currentOrientationIsLandscape: Bool? { get }
}

final class InterfaceOrientationStream: InterfaceOrientationStreaming {

    init() {

        updateSubject()

        // We listen for device orientation changes (which are more sensitive)
        // but we use the interface orientation of the key window to actually determine the rotation of the UI
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.currentOrientationIsLandscape = windowScene.interfaceOrientation.isLandscape
            self?.subject.onNext(windowScene.interfaceOrientation.isLandscape)
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

    var isLandscape: PublishSubject<Bool> {
        return subject
    }

    var currentOrientationIsLandscape: Bool?
    private let subject = PublishSubject<Bool>()
}
