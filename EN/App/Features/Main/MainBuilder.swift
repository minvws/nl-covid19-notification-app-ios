/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

/// @mockable
protocol MainViewControllable: ViewControllable {
    func attachStatus()
    func attachMoreInformation()
    
    func embed(stackedViewController: ViewControllable)
}

/// @mockable
protocol MainBuildable {
    func build() -> ViewControllable
}

protocol MainDependency {
    
}

final class MainDependencyProvider: DependencyProvider<MainDependency>, StatusDependency, MoreInformationDependency {
    var statusBuilder: StatusBuildable {
        return StatusBuilder(dependency: self)
    }
    
    var moreInformationBuilder: MoreInformationBuildable {
        return MoreInformationBuilder(dependency: self)
    }
}

final class MainBuilder: Builder<MainDependency>, MainBuildable {
    func build() -> ViewControllable {
        let dependencyProvider = MainDependencyProvider(dependency: dependency)
        
        return MainViewController(statusBuilder: dependencyProvider.statusBuilder,
                                  moreInformationBuilder: dependencyProvider.moreInformationBuilder)
    }
}
