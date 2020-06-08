/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

/// @mockable
protocol MainViewControllable: ViewControllable {
    
}

/// @mockable
protocol MainBuildable {
    func build() -> ViewControllable
}

final class MainBuilder: Builder<EmptyDependency>, MainBuildable {
    func build() -> ViewControllable {
        return MainViewController()
    }
}
