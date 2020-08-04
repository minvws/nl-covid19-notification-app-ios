/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation

enum CardType {
    case exposureOff
    case bluetoothOff
    case noInternet(retryHandler: () -> ())
    case noLocalNotifications
}

protocol CardTypeSettable {
    var type: CardType { get set }
}

/// @mockable
protocol CardBuildable {
    /// Builds CardViewController
    func build(type: CardType) -> Routing & CardTypeSettable
}

protocol CardDependency {
    var theme: Theme { get }
    var bluetoothEnabledStream: AnyPublisher<Bool, Never> { get }
}

private final class CardDependencyProvider: DependencyProvider<CardDependency>, EnableSettingDependency {

    var bluetoothEnabledStream: AnyPublisher<Bool, Never> {
        return dependency.bluetoothEnabledStream
    }

    var enableSettingBuilder: EnableSettingBuildable {
        return EnableSettingBuilder(dependency: self)
    }

    var theme: Theme {
        return dependency.theme
    }
}

final class CardBuilder: Builder<CardDependency>, CardBuildable {
    func build(type: CardType) -> Routing & CardTypeSettable {
        let dependencyProvider = CardDependencyProvider(dependency: dependency)

        let viewController = CardViewController(theme: dependencyProvider.dependency.theme,
                                                type: type)

        return CardRouter(viewController: viewController,
                          enableSettingBuilder: dependencyProvider.enableSettingBuilder)
    }
}
