/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import RxSwift
import SnapshotTesting
import XCTest

class TestCase: XCTestCase {

    var disposeBag = DisposeBag()

    var recordSnapshots: Bool {
        get { SnapshotTesting.record }
        set { SnapshotTesting.record = newValue }
    }

    var forceRecordAllSnapshots = false

    let theme = ENTheme()

    // MARK: - Overrides

    override func setUp() {
        super.setUp()
        SnapshotTesting.diffTool = "ksdiff"

        let now = Date()
        DateTimeTestingOverrides.overriddenCurrentDate = now
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        LocalizationOverrides.overriddenCurrentLanguageIdentifier = nil
        LocalizationOverrides.overriddenIsRTL = nil
        LocalizationOverrides.overriddenLocalization = nil
        DateTimeTestingOverrides.overriddenCurrentDate = nil
        AnimationTestingOverrides.animationsEnabled = nil
        WebViewTestingOverrides.webViewLoadingEnabled = nil
    }

    func snapshots(
        matching viewController: UIViewController,
        as snapshotting: Snapshotting<UIViewController, UIImage>? = nil,
        named name: String? = nil,
        record recording: Bool = false,
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line,
        waitForMainThread: Bool = false
    ) {

        var completionExpectation: XCTestExpectation?
        if waitForMainThread {
            completionExpectation = expectation(description: "snapshotCompletion")
        }

        var snapshots = [
            Snapshotting.image(on: .iPhoneSe),
            Snapshotting.image(on: .iPhoneX),
            Snapshotting.image(on: .iPhoneXsMax)
        ]

        if let snapshotting = snapshotting {
            snapshots.append(snapshotting)
        }

        let localization = LocalizationOverrides.overriddenLocalization ?? ""

        func doSnapShot() {
            assertSnapshots(matching: viewController,
                            as: snapshots,
                            record: recording,
                            timeout: timeout,
                            file: file,
                            testName: testName + localization,
                            line: line)
        }

        if waitForMainThread {
            DispatchQueue.main.async {
                doSnapShot()
                completionExpectation?.fulfill()
            }

            waitForExpectations(timeout: 10, handler: { error in
                if error != nil {
                    XCTFail("Failed waiting for main queue after asserting snapshot")
                }
            })

        } else {
            doSnapShot()
        }
    }

    func waitForExpectations() {
        waitForExpectations(timeout: 5, handler: nil)
    }

    func snapshotWrapper(_ wrappedView: UIView, width: CGFloat = 320, height: CGFloat? = nil) -> UIView {
        let view = UIView(frame: .zero)
        view.snp.makeConstraints { maker in
            maker.width.equalTo(width)
            if let height = height {
                maker.height.equalTo(height)
            }
        }

        view.addSubview(wrappedView)
        wrappedView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.top.equalToSuperview()
        }

        return view
    }
}
