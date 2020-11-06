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
    func build(listener: CardListener?, types: [CardType]) -> Routing & CardTypeSettable
}

protocol CardDependency {
    var theme: Theme { get }
    var bluetoothStateStream: BluetoothStateStreaming { get }
    var environmentController: EnvironmentControlling { get }
    var dataController: ExposureDataControlling { get }
}

protocol CardListener: AnyObject {
    func dismissedAnnouncement()
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

    var dataController: ExposureDataControlling {
        return dependency.dataController
    }
}

final class CardBuilder: Builder<CardDependency>, CardBuildable {
    func build(listener: CardListener?, types: [CardType]) -> Routing & CardTypeSettable {
        let dependencyProvider = CardDependencyProvider(dependency: dependency)

        let viewController = CardViewController(listener: listener,
                                                theme: dependencyProvider.dependency.theme,
                                                types: types,
                                                dataController: dependencyProvider.dataController)

        return CardRouter(viewController: viewController,
                          enableSettingBuilder: dependencyProvider.enableSettingBuilder)
    }
}
