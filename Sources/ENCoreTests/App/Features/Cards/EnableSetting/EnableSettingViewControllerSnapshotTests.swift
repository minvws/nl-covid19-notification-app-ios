/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import SnapshotTesting
import XCTest

final class EnableSettingViewControllerSnapshotTests: TestCase {
    private var viewController: EnableSettingViewController!
    private var exposureStateStream = ExposureStateStreamingMock()
    private var environmentController = EnvironmentControllingMock()

    override func setUp() {
        super.setUp()

        exposureStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .notAuthorized)
        
        recordSnapshots = false
    }

    func test_enableBluetooth() {
        viewController = EnableSettingViewController(listener: EnableSettingListenerMock(),
                                                     theme: theme,
                                                     setting: .enableBluetooth,
                                                     exposureStateStream: exposureStateStream,
                                                     environmentController: environmentController)

        snapshots(matching: viewController)
    }

    func test_enableExposureNotifications() {
        environmentController.isiOS137orHigher = false
        viewController = EnableSettingViewController(listener: EnableSettingListenerMock(),
                                                     theme: theme,
                                                     setting: .enableExposureNotifications,
                                                     exposureStateStream: exposureStateStream,
                                                     environmentController: environmentController)

        snapshots(matching: viewController)
    }

    func test_enableExposureNotifications_extended() {
        environmentController.isiOS137orHigher = true
        viewController = EnableSettingViewController(listener: EnableSettingListenerMock(),
                                                     theme: theme,
                                                     setting: .enableExposureNotifications,
                                                     exposureStateStream: exposureStateStream,
                                                     environmentController: environmentController)

        snapshots(matching: viewController)
    }

    func test_enableLocalNotifications() {        
        viewController = EnableSettingViewController(listener: EnableSettingListenerMock(),
                                                     theme: theme,
                                                     setting: .enableLocalNotifications,
                                                     exposureStateStream: exposureStateStream,
                                                     environmentController: environmentController)

        snapshots(matching: viewController)
    }
    
    func test_enableInternet() {
        viewController = EnableSettingViewController(listener: EnableSettingListenerMock(),
                                                     theme: theme,
                                                     setting: .connectToInternet,
                                                     exposureStateStream: exposureStateStream,
                                                     environmentController: environmentController)

        snapshots(matching: viewController)
    }

    func test_updateOperatingSystem() {
        viewController = EnableSettingViewController(listener: EnableSettingListenerMock(),
                                                     theme: theme,
                                                     setting: .updateOperatingSystem,
                                                     exposureStateStream: exposureStateStream,
                                                     environmentController: environmentController)

        snapshots(matching: viewController)
    }

    func test_updateOperatingSystem_arabic() {

        LocalizationOverrides.overriddenLocalization = "ar"
        LocalizationOverrides.overriddenIsRTL = true
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "ar"

        viewController = EnableSettingViewController(listener: EnableSettingListenerMock(),
                                                     theme: theme,
                                                     setting: .updateOperatingSystem,
                                                     exposureStateStream: exposureStateStream,
                                                     environmentController: environmentController)

        snapshots(matching: viewController)

        LocalizationOverrides.overriddenLocalization = nil
        LocalizationOverrides.overriddenIsRTL = nil
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = nil
    }
}
