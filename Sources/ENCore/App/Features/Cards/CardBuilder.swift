/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

enum CardType {
    case exposureOff
    case bluetoothOff
    case noInternet(retryHandler: () -> ())
    case noLocalNotifications
    case interopAnnouncement
}

protocol CardTypeSettable {
    var types: [CardType] { get set }
}

/// @mockable
protocol CardBuildable {
    /// Builds CardViewController
    func build(types: [CardType]) -> Routing & CardTypeSettable
}

protocol CardDependency {
    var theme: Theme { get }
    var bluetoothStateStream: BluetoothStateStreaming { get }
    var environmentController: EnvironmentControlling { get }
}

private final class CardDependencyProvider: DependencyProvider<CardDependency>, EnableSettingDependency {

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
}

final class CardBuilder: Builder<CardDependency>, CardBuildable {
    func build(types: [CardType]) -> Routing & CardTypeSettable {
        let dependencyProvider = CardDependencyProvider(dependency: dependency)

        let viewController = CardViewController(theme: dependencyProvider.dependency.theme,
                                                types: types)

        return CardRouter(viewController: viewController,
                          enableSettingBuilder: dependencyProvider.enableSettingBuilder)
    }
}
