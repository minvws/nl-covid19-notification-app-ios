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
        XCTAssertEqual(sut.manifestUrl(useFallback: false)?.absoluteString,
                       "https://test.coronamelder-dist.nl/\(sut.cdn.path)/manifest")
    }

    func test_manifestUrl_withFallbackUrl() {
        XCTAssertEqual(sut.manifestUrl(useFallback: true)?.absoluteString,
                       "https://test.coronamelder-dist.nl/\(sut.cdn.signatureFallbackPath!)/manifest")
    }

    func test_exposureKeySetUrl() {
        XCTAssertEqual(sut.exposureKeySetUrl(useFallback: false, identifier: "identifier")?.absoluteString,
                       "https://test.coronamelder-dist.nl/\(sut.cdn.path)/exposurekeyset/identifier")
    }

    func test_exposureKeySetUrl_withFallbackUrl() {
        XCTAssertEqual(sut.exposureKeySetUrl(useFallback: true, identifier: "identifier")?.absoluteString,
                       "https://test.coronamelder-dist.nl/\(sut.cdn.signatureFallbackPath!)/exposurekeyset/identifier")
    }

    func test_riskCalculationParametersUrl() {
        XCTAssertEqual(sut.riskCalculationParametersUrl(useFallback: false, identifier: "identifier")?.absoluteString,
                       "https://test.coronamelder-dist.nl/\(sut.cdn.path)/riskcalculationparameters/identifier")
    }

    func test_riskCalculationParametersUrl_withFallbackUrl() {
        XCTAssertEqual(sut.riskCalculationParametersUrl(useFallback: true, identifier: "identifier")?.absoluteString,
                       "https://test.coronamelder-dist.nl/\(sut.cdn.signatureFallbackPath!)/riskcalculationparameters/identifier")
    }

    func test_appConfigUrl() {
        XCTAssertEqual(sut.appConfigUrl(useFallback: false, identifier: "identifier")?.absoluteString,
                       "https://test.coronamelder-dist.nl/\(sut.cdn.path)/appconfig/identifier")
    }

    func test_appConfigUrl_withFallbackUrl() {
        XCTAssertEqual(sut.appConfigUrl(useFallback: true, identifier: "identifier")?.absoluteString, "https://test.coronamelder-dist.nl/\(sut.cdn.signatureFallbackPath!)/appconfig/identifier")
    }

    func test_treatmentPerspectiveUrl() {
        XCTAssertEqual(sut.treatmentPerspectiveUrl(useFallback: false, identifier: "identifier")?.absoluteString, "https://test.coronamelder-dist.nl/\(sut.cdn.path)/resourcebundle/identifier")
    }

    func test_treatmentPerspectiveUrl_withFallbackUrl() {
        XCTAssertEqual(sut.treatmentPerspectiveUrl(useFallback: true, identifier: "identifier")?.absoluteString, "https://test.coronamelder-dist.nl/\(sut.cdn.signatureFallbackPath!)/resourcebundle/identifier")
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
