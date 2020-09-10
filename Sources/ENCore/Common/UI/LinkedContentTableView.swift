/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

protocol LinkedContent {
    var title: String { get }
}

final class LinkedContentTableViewManager: NSObject, UITableViewDelegate, UITableViewDataSource {

    var selectedContentHandler: ((LinkedContent) -> ())?

    init(content: [LinkedContent], theme: Theme) {
        self.content = content
        self.theme = theme
        super.init()
        headerView.label.text = .helpAlsoRead
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = HelpTableViewCell(theme: theme, reuseIdentifier: "HelpDetailQuestionCell")

        cell.textLabel?.text = content[indexPath.row].title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = theme.fonts.bodyBold
        cell.textLabel?.accessibilityTraits = .header

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return content.isEmpty ? UIView() : headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedContentHandler?(content[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private let content: [LinkedContent]
    private let theme: Theme

    private lazy var headerView: HelpTableViewSectionHeaderView = HelpTableViewSectionHeaderView(theme: self.theme)
}

final class LinkedContentTableView: HelpTableView {

    init(manager: LinkedContentTableViewManager) {
        super.init()
        delegate = manager
        dataSource = manager
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
