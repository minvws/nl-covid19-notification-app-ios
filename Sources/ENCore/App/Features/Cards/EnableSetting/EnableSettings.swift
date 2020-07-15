/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct EnableSetting {
    let title: String
    let steps: [EnableSettingStep]
    let action: () -> ()
    let actionTitle: String
}

struct EnableSettingStep {
    let description: String
    let image: Image
}
