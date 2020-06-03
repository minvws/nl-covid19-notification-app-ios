/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import XCTest

class ENUnitTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testOnboardingSteps() throws {

        let onboardingSteps = OnboardingManager.shared.onboardingSteps

        for (index, onboardingStep) in onboardingSteps.enumerated() {
            XCTAssertTrue(onboardingStep.title == Localized("step\(index+1)Title"))
            XCTAssertTrue(onboardingStep.content == Localized("step\(index+1)Content"))
            XCTAssertNotNil(onboardingStep.image)
            XCTAssertTrue(!onboardingStep.buttonTitle.isEmpty)
            XCTAssertTrue(onboardingStep.attributedText.length > 0)
        }
    }
}
