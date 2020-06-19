/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import Foundation

final class BackgroundController: BackgroundControlling {
    func schedule(taskIdentifier: String, launchHandler: @escaping (BGTask) -> ()) {}
}
