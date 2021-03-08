/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

extension UITableView {

    func isFirstItem(_ indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 && indexPath.row == 0
    }

    func isLastItem(_ indexPath: IndexPath) -> Bool {
        let indexOfLastSection = numberOfSections > 0 ? numberOfSections - 1 : 0
        let indexOfLastRowInLastSection = numberOfRows(inSection: indexOfLastSection) - 1

        return indexPath.section == indexOfLastSection && indexPath.row == indexOfLastRowInLastSection
    }

    func isFirstItemOfSection(_ indexPath: IndexPath) -> Bool {
        return indexPath.row == 0
    }

    func isLastItemOfSection(_ indexPath: IndexPath) -> Bool {
        return indexPath.row == (numberOfRows(inSection: indexPath.section) - 1)
    }

    func addListAccessibilityHint(cell: UITableViewCell, indexPath: IndexPath) {
        if isFirstItemOfSection(indexPath) {
            cell.accessibilityHint = .accessibilityStartOfList
        } else if isLastItemOfSection(indexPath) {
            cell.accessibilityHint = .accessibilityEndOfList
        } else {
            cell.accessibilityHint = nil
        }
    }
}
