/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class NetworkManagerURLSessionDelegateTests: TestCase {

    private var sut: NetworkManagerURLSessionDelegate!

    private var mockNetworkConfigurationProvider: NetworkConfigurationProviderMock!

    override func setUp() {
        super.setUp()

        mockNetworkConfigurationProvider = NetworkConfigurationProviderMock()

        sut = NetworkManagerURLSessionDelegate(configurationProvider: mockNetworkConfigurationProvider)
    }
}
