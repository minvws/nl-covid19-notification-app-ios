/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum CardType {
    case exposureOff
    case bluetoothOff
    case noInternet(retryHandler: () -> ())
    case noLocalNotifications
}

protocol CardViewControllable: ViewControllable {
    var type: CardType { get set }
}

/// @mockable
protocol CardBuildable {
    /// Builds CardViewController
    func build(type: CardType) -> CardViewControllable
}

protocol CardDependency {
    var theme: Theme { get }
}

private final class CardDependencyProvider: DependencyProvider<CardDependency> {}

final class CardBuilder: Builder<CardDependency>, CardBuildable {
    func build(type: CardType) -> CardViewControllable {
        let dependencyProvider = CardDependencyProvider(dependency: dependency)

        return CardViewController(theme: dependencyProvider.dependency.theme,
                                  type: type)
    }
}
