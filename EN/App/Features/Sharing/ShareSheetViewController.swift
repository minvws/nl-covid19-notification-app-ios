/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import UIKit

/// @mockable
protocol ShareSheetViewControllable: ViewControllable {
    
}

final class ShareSheetViewController: ViewController, ShareSheetViewControllable {
    
    init(listener: ShareSheetListener, theme: Theme) {
        self.listener = listener
        
        super.init(theme: theme)
    }
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Implement or delete
    }
    
    // MARK: - Private
    
    private weak var listener: ShareSheetListener?
}
