//
//  FeatureFlags.swift
//  ENCore
//
//  Created by Roel Spruit on 19/05/2021.
//

import Foundation

struct Feature {
    let isEnabled: Bool
}

protocol FeatureFlagControlling {
    var backgroundKeysetDownloading: Feature { get }
}

class FeatureFlagController: FeatureFlagControlling {
    
    static let shared = FeatureFlagController()
    
    private init() {}
    
    var backgroundKeysetDownloading = Feature(isEnabled: true)
}
