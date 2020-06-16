//
//  ENTheme.swift
//  EN
//
//  Created by Cameron Mc Gorian on 16/06/2020.
//

import Foundation
import UIKit

public protocol Theme: AnyObject {
    var fonts: Fonts { get }
    var colors: Colors { get }
    
    init()
}

public protocol Themeable {
    var theme: Theme { get }
}

final class ENTheme: Theme {
    let fonts: Fonts
    let colors: Colors
    
    init() {
        self.fonts = ENFonts()
        self.colors = ENColors()
    }
}
