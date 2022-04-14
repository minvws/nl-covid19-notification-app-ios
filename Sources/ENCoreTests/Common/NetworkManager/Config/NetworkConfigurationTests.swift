/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

class NetworkConfigurationTests: TestCase {

    var sut: NetworkConfiguration!

    override func setUpWithError() throws {
        sut = .test
    }

    func test_manifestUrl() {
        XCTAssertEqual(sut.manifestUrl?.absoluteString,
                       "https://test.coronamelder-dist.nl/\(sut.cdn.path)/manifest")
    }

    func test_exposureKeySetUrl() {
        XCTAssertEqual(sut.exposureKeySetUrl(identifier: "identifier")?.absoluteString,
                       "https://test.coronamelder-dist.nl/\(sut.cdn.path)/exposurekeyset/identifier")
    }

    func test_riskCalculationParametersUrl() {
        XCTAssertEqual(sut.riskCalculationParametersUrl(identifier: "identifier")?.absoluteString,
                       "https://test.coronamelder-dist.nl/\(sut.cdn.path)/riskcalculationparameters/identifier")
    }

    func test_appConfigUrl() {
        XCTAssertEqual(sut.appConfigUrl(identifier: "identifier")?.absoluteString,
                       "https://test.coronamelder-dist.nl/\(sut.cdn.path)/appconfig/identifier")
    }

    func test_treatmentPerspectiveUrl() {
        XCTAssertEqual(sut.treatmentPerspectiveUrl(identifier: "identifier")?.absoluteString, "https://test.coronamelder-dist.nl/\(sut.cdn.path)/resourcebundle/identifier")
    }

    func test_registerUrl() {
        XCTAssertEqual(sut.registerUrl?.absoluteString, "https://test.coronamelder-api.nl/v2/register")
    }

    func test_postKeysUrl() {
        XCTAssertEqual(sut.postKeysUrl(signature: "signature")?.absoluteString, "https://test.coronamelder-api.nl/\(sut.api.path)/postkeys?sig=signature")
    }

    func test_stopKeysUrl() {
        XCTAssertEqual(sut.stopKeysUrl(signature: "signature")?.absoluteString, "https://test.coronamelder-api.nl/\(sut.api.path)/stopkeys?sig=signature")
    }
}
