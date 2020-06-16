/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation



///
/// We need to refactor this class to fit within the framework !!!!!!!!
///

@propertyWrapper
class Persisted<Value: Codable> {
    
    let userDefaultsKey: String
    let notificationName: Notification.Name
    init(userDefaultsKey: String, notificationName: Notification.Name, defaultValue: Value) {
        self.userDefaultsKey = userDefaultsKey
        self.notificationName = notificationName
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                wrappedValue = try JSONDecoder().decode(Value.self, from: data)
            } catch {
                wrappedValue = defaultValue
            }
        } else {
            wrappedValue = defaultValue
        }
    }
    
    var wrappedValue: Value {
        didSet {
            UserDefaults.standard.set(try! JSONEncoder().encode(wrappedValue), forKey: userDefaultsKey)
        }
    }
    
    var projectedValue: Persisted<Value> { self }
}
class LocalStore {
    
    static let shared = LocalStore()
    
    @Persisted(userDefaultsKey: "manifest", notificationName: .init("ManifestDidChange"), defaultValue: nil)
    var manifest: Manifest?
    
    @Persisted(userDefaultsKey: "appConfig", notificationName: .init("AppConfigDidChange"), defaultValue: nil)
    var appConfig: AppConfig?
    
    @Persisted(userDefaultsKey: "riskCalculationParameters", notificationName: .init("RiskCalculationParametersDidChange"), defaultValue: nil)
    var riskCalculationParameters: RiskCalculationParameters?
}
