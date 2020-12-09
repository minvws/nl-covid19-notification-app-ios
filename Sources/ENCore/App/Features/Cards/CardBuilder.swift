/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

enum CardType: Equatable {
    case exposureOff
    case bluetoothOff
    case noInternet(retryHandler: () -> ())
    case noLocalNotifications
    case interopAnnouncement

    static func == (lhs: CardType, rhs: CardType) -> Bool {
        switch (lhs, rhs) {
        case (.exposureOff, .exposureOff), (.bluetoothOff, .bluetoothOff), (.noInternet, .noInternet), (.noLocalNotifications, .noLocalNotifications), (.interopAnnouncement, .interopAnnouncement):
            return true
        default:
            return false
        }
    }
}

protocol CardTypeSettable {
    var types: [CardType] { get set }
}

/// @mockable
protocol CardBuildable {
    /// Builds CardViewController
    func build(listener: CardListening?, types: [CardType]) -> Routing & CardTypeSettable
}

/// @mockable
protocol CardDependency {
    var theme: Theme { get }
    var bluetoothStateStream: BluetoothStateStreaming { get }
    var environmentController: EnvironmentControlling { get }
    var dataController: ExposureDataControlling { get }
}

/// @mockable
protocol CardListening: AnyObject {
    func dismissedAnnouncement()
}

private final class CardDependencyProvider: DependencyProvider<CardDependency>, EnableSettingDependency, WebviewDependency {

    var bluetoothStateStream: BluetoothStateStreaming {
        return dependency.bluetoothStateStream
    }

    var enableSettingBuilder: EnableSettingBuildable {
        return EnableSettingBuilder(dependency: self)
    }

    var theme: Theme {
        return dependency.theme
    }

    var environmentController: EnvironmentControlling {
        return dependency.environmentController
    }

    var dataController: ExposureDataControlling {
        return dependency.dataController
    }

    var webviewBuilder: WebviewBuildable {
        return WebviewBuilder(dependency: self)
    }
}

final class CardBuilder: Builder<CardDependency>, CardBuildable {
    func build(listener: CardListening?, types: [CardType]) -> Routing & CardTypeSettable {
        let dependencyProvider = CardDependencyProvider(dependency: dependency)

        let viewController = CardViewController(listener: listener,
                                                theme: dependencyProvider.dependency.theme,
                                                types: types,
                                                dataController: dependencyProvider.dataController)

        return CardRouter(viewController: viewController,
                          enableSettingBuilder: dependencyProvider.enableSettingBuilder,
                          webviewBuilder: dependencyProvider.webviewBuilder)
    }
}
