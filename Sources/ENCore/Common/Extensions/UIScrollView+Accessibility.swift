/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

extension UIScrollView {

    func addListSubview(_ view: UIView, index: Int, total: Int) {
        if total > 1 {
            if index == 0 {
                view.accessibilityHint = .accessibilityStartOfList
            } else if index == total - 1 {
                view.accessibilityHint = .accessibilityEndOfList
            }
        }
        addSubview(view)
    }
}
