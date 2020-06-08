/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

open class View: UIView {
    convenience init() {
        let frame = CGRect(x: 0,
                           y: 0,
                           width: UIScreen.main.bounds.width,
                           height: UIScreen.main.bounds.height)
        
        self.init(frame: frame)
        
        configure()
    }
    
    func configure() {
        build()
        setupConstraints()
    }
    
    open func build() {
        
    }
    
    open func setupConstraints() {
        
    }
}
