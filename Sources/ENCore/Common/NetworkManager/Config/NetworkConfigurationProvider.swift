/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

protocol NetworkConfigurationProvider {
    var configuration: NetworkConfiguration { get }
}

final class StaticNetworkConfigurationProvider: NetworkConfigurationProvider {
    init(configuration: NetworkConfiguration) {
        self.networkConfiguration = configuration
    }

    // MARK: - NetworkConfigurationProvider

    var configuration: NetworkConfiguration {
        return networkConfiguration
    }

    // MARK: - Private

    private let networkConfiguration: NetworkConfiguration
}

final class DynamicNetworkConfigurationProvider: NetworkConfigurationProvider {
    init(configurationStream: NetworkConfigurationStreaming) {
        self.configurationStream = configurationStream
    }

    // MARK: - NetworkConfigurationProvider

    var configuration: NetworkConfiguration {
        return configurationStream.configuration
    }

    // MARK: - Private

    private let configurationStream: NetworkConfigurationStreaming
}

protocol NetworkConfigurationStreaming {
    var configuration: NetworkConfiguration { get }
}

protocol MutableNetworkConfigurationStreaming: NetworkConfigurationStreaming {
    func update(configuration: NetworkConfiguration)
}

final class NetworkConfigurationStream: MutableNetworkConfigurationStreaming {
    init(configuration: NetworkConfiguration) {
        self.configuration = configuration
    }

    // MARK: - MutableNetworkConfigurationStreaming

    func update(configuration: NetworkConfiguration) {
        self.configuration = configuration
    }

    // MARK: - NetworkConfigurationStreaming

    var configuration: NetworkConfiguration
}
