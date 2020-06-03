/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

class Haptic {

    static func light() {
        let ifg = UIImpactFeedbackGenerator(style: .light)
        ifg.prepare()
        ifg.impactOccurred()
    }
    
    static func medium() {
        let ifg = UIImpactFeedbackGenerator(style: .medium)
        ifg.prepare()
        ifg.impactOccurred()
    }
    
    static func heavy() {
        let ifg = UIImpactFeedbackGenerator(style: .heavy)
        ifg.prepare()
        ifg.impactOccurred()
    }
}
