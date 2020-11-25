/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import SnapshotTesting
import XCTest

class WebViewErrorViewSnapshotTests: TestCase {

    private var sut: WebViewErrorView!

    override func setUpWithError() throws {
        recordSnapshots = true
        sut = WebViewErrorView(theme: theme)
    }

    func test_webviewErrorView() throws {
        sut.snp.makeConstraints { maker in
            maker.width.equalTo(320)
            maker.height.equalTo(720)
        }

        assertSnapshot(matching: sut, as: .image())
    }
}
