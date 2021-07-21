/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol AboutListener: AnyObject {
    func aboutRequestsDismissal(shouldHideViewController: Bool)
}

/// @mockable
protocol AboutBuildable {
    func build(withListener listener: AboutListener) -> Routing
}

protocol AboutDependency {
    var theme: Theme { get }
    var exposureController: ExposureControlling { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
}

private final class AboutDependencyProvider: DependencyProvider<AboutDependency>, AboutOverviewDependency, HelpDetailDependency, AppInformationDependency, TechnicalInformationDependency, WebviewDependency, ReceivedNotificationDependency {

    // MARK: - HelpOverviewDependency

    var aboutManager: AboutManaging {
        return AboutManager()
    }

    // MARK: - Forwarding Dependencies

    var theme: Theme {
        return dependency.theme
    }

    var interfaceOrientationStream: InterfaceOrientationStreaming {
        dependency.interfaceOrientationStream
    }

    // MARK: - Child Builders

    var overviewBuilder: AboutOverviewBuildable {
        return AboutOverviewBuilder(dependency: self)
    }

    var detailBuilder: HelpDetailBuildable {
        return HelpDetailBuilder(dependency: self)
    }

    var appInformationBuilder: AppInformationBuildable {
        return AppInformationBuilder(dependency: self)
    }

    var technicalInformationBuilder: TechnicalInformationBuildable {
        return TechnicalInformationBuilder(dependency: self)
    }

    var webviewBuilder: WebviewBuilder {
        return WebviewBuilder(dependency: self)
    }

    var receivedNotificationBuilder: ReceivedNotificationBuildable {
        return ReceivedNotificationBuilder(dependency: self)
    }

    var exposureController: ExposureControlling {
        return dependency.exposureController
    }
}

final class AboutBuilder: Builder<AboutDependency>, AboutBuildable {

    func build(withListener listener: AboutListener) -> Routing {
        let dependencyProvider = AboutDependencyProvider(dependency: dependency)
        let viewController = AboutViewController(listener: listener,
                                                 theme: dependencyProvider.dependency.theme)

        return AboutRouter(viewController: viewController,
                           aboutOverviewBuilder: dependencyProvider.overviewBuilder,
                           helpDetailBuilder: dependencyProvider.detailBuilder,
                           appInformationBuilder: dependencyProvider.appInformationBuilder,
                           technicalInformationBuilder: dependencyProvider.technicalInformationBuilder,
                           webviewBuilder: dependencyProvider.webviewBuilder,
                           receivedNotificationBuilder: dependencyProvider.receivedNotificationBuilder,
                           exposureController: dependencyProvider.exposureController)
    }
}
