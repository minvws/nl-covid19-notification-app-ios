/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import RxSwift
import XCTest

class ExposureDetectionControllerTests: XCTestCase {

    private var sut: ExposureDetectionController!
    private var mockExposureManager: ExposureManagingMock!

    private let disposeBag = DisposeBag()

    override func setUpWithError() throws {

        mockExposureManager = ExposureManagingMock()

        sut = ExposureDetectionController(exposureManager: mockExposureManager)
    }

    func test_detectExposures_shouldCallExposureManager() {
        let configuration = ExposureConfigurationMock(minimumRiskScope: 20)
        let diagnosisKeyURLs = [URL(string: "http://www.someLocalURL.com")!]

        let exp = expectation(description: "success")

        let summary = mockDetectExposures()
        mockGetExposureWindows()

        sut.detectExposures(configuration: configuration, diagnosisKeyURLs: diagnosisKeyURLs)
            .subscribe(onSuccess: { result in
                XCTAssertTrue(result.wasExposed)
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 1)
        XCTAssertEqual(mockExposureManager.detectExposuresArgValues.first?.0.minimumRiskScope, 20)
        XCTAssertEqual(mockExposureManager.detectExposuresArgValues.first?.1.first?.absoluteString, "http://www.someLocalURL.com")

        XCTAssertEqual(mockExposureManager.getExposureWindowsCallCount, 1)
        XCTAssertTrue(mockExposureManager.getExposureWindowsArgValues.first as! ExposureDetectionSummaryMock === summary)
    }

    @discardableResult
    private func mockDetectExposures() -> ExposureDetectionSummaryMock {
        let summary = ExposureDetectionSummaryMock()
        mockExposureManager.detectExposuresHandler = { _, _, completion in
            completion(.success(summary))
        }
        return summary
    }

    @discardableResult
    private func mockGetExposureWindows() -> [ExposureWindow] {
        let exposureWindows: [ExposureWindow] = [
            ExposureWindowMock()
        ]
        mockExposureManager.getExposureWindowsHandler = { _, completion in
            completion(.success(exposureWindows))
        }

        return exposureWindows
    }
}
