/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

/// @mockable
protocol MainBuildable {
    func build() -> Routing
}

protocol MainDependency {
    var theme: Theme { get }
    var exposureStateStream: ExposureStateStreaming { get }
}

final class MainDependencyProvider: DependencyProvider<MainDependency>, StatusDependency, MoreInformationDependency, AboutDependency, ReceivedNotificationDependency, RequestTestDependency, InfectedDependency {

    var theme: Theme {
        return dependency.theme
    }

    var exposureStateStream: ExposureStateStreaming {
        return dependency.exposureStateStream
    }

    var statusBuilder: StatusBuildable {
        return StatusBuilder(dependency: self)
    }

    var moreInformationBuilder: MoreInformationBuildable {
        return MoreInformationBuilder(dependency: self)
    }

    var aboutBuilder: AboutBuildable {
        return AboutBuilder(dependency: self)
    }

    var receivedNotificationBuilder: ReceivedNotificationBuildable {
        return ReceivedNotificationBuilder(dependency: self)
    }

    var requestTestBuilder: RequestTestBuildable {
        return RequestTestBuilder(dependency: self)
    }

    var infectedBuilder: InfectedBuildable {
        return InfectedBuilder(dependency: self)
    }
}

final class MainBuilder: Builder<MainDependency>, MainBuildable {
    func build() -> Routing {
        let dependencyProvider = MainDependencyProvider(dependency: dependency)
        let viewController = MainViewController(theme: dependencyProvider.dependency.theme)

        return MainRouter(viewController: viewController,
                          statusBuilder: dependencyProvider.statusBuilder,
                          moreInformationBuilder: dependencyProvider.moreInformationBuilder,
                          aboutBuilder: dependencyProvider.aboutBuilder,
                          receivedNotificationBuilder: dependencyProvider.receivedNotificationBuilder,
                          requestTestBuilder: dependencyProvider.requestTestBuilder,
                          infectedBuilder: dependencyProvider.infectedBuilder)
    }
}
