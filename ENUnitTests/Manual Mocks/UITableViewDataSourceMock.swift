/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

final class UITableViewDataSourceMock: NSObject, UITableViewDataSource {
    var numberOfSectionsCallCount: Int = 0
    var numberOfSectionsHandler: ((UITableView) -> Int)?

    func numberOfSections(in tableView: UITableView) -> Int {
        numberOfSectionsCallCount += 1

        return numberOfSectionsHandler?(tableView) ?? 0
    }

    var numberOfRowsCallCount: Int = 0
    var numberOfRowsHandler: ((UITableView, Int) -> Int)?

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfRowsCallCount += 1

        return numberOfRowsHandler?(tableView, section) ?? 0
    }

    var cellForRowAtCallCount: Int = 0
    var cellForRowAtHandler: ((UITableView, IndexPath) -> UITableViewCell)?

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellForRowAtCallCount += 1

        return cellForRowAtHandler?(tableView, indexPath) ?? UITableViewCell()
    }
}
