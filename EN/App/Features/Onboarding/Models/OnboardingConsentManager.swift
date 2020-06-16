/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import UIKit

/// @mockable
protocol OnboardingConsentManaging {
    var onboardingConsentSteps: [OnboardingConsentStep] { get }

    func getStep(_ index: Int) -> OnboardingConsentStep?
    func getNextConsentStep(_ currentStep: OnboardingConsentStepIndex) -> OnboardingConsentStepIndex?

    func askEnableExposureNotifications(_ completion: @escaping ((_ exposureActiveState: ExposureActiveState) -> ()))
    func goToBluetoothSettings(_ completion: @escaping (() -> ()))
    func askNotificationsAuthorization(_ completion: @escaping (() -> ()))
}

final class OnboardingConsentManager: OnboardingConsentManaging {

    var onboardingConsentSteps: [OnboardingConsentStep] = []

    init(exposureStateStream: ExposureStateStreaming,
         exposureController: ExposureControlling,
         theme: Theme) {

        self.exposureStateStream = exposureStateStream
        self.exposureController = exposureController

        onboardingConsentSteps.append(
            OnboardingConsentStep(
                step: .en,
                theme: theme,
                title: Localized("consentStep1Title"),
                content: Localized("consentStep1Content"),
                image: nil,
                summarySteps: [
                    OnboardingConsentSummaryStep(
                        title: NSAttributedString(string: Localized("consentStep1Summary1")),
                        image: UIImage(named: "CheckmarkShield")
                    ),
                    OnboardingConsentSummaryStep(
                        title: NSAttributedString(string: Localized("consentStep1Summary2")),
                        image: UIImage(named: "CheckmarkShield")
                    ),
                    OnboardingConsentSummaryStep(
                        title: NSAttributedString(string: Localized("consentStep1Summary3")),
                        image: UIImage(named: "CheckmarkShield")
                    )
                ],
                primaryButtonTitle: Localized("consentStep1PrimaryButton"),
                secondaryButtonTitle: Localized("consentStep1SecondaryButton"),
                hasNavigationBarSkipButton: true
            )
        )

        onboardingConsentSteps.append(
            OnboardingConsentStep(
                step: .bluetooth,
                theme: theme,
                title: Localized("consentStep2Title"),
                content: Localized("consentStep2Content"),
                image: UIImage(named: "PleaseTurnOnBluetooth"),
                summarySteps: nil,
                primaryButtonTitle: Localized("consentStep2PrimaryButton"),
                secondaryButtonTitle: Localized("consentStep2SecondaryButton"),
                hasNavigationBarSkipButton: false
            )
        )

        onboardingConsentSteps.append(
            OnboardingConsentStep(
                step: .notifications,
                theme: theme,
                title: Localized("consentStep3Title"),
                content: Localized("consentStep3Content"),
                image: UIImage(named: "PleaseTurnOnNotifications"),
                summarySteps: nil,
                primaryButtonTitle: Localized("consentStep3PrimaryButton"),
                secondaryButtonTitle: Localized("consentStep3SecondaryButton"),
                hasNavigationBarSkipButton: false
            )
        )
    }

    // MARK: - Functions

    func getStep(_ index: Int) -> OnboardingConsentStep? {
        if self.onboardingConsentSteps.count > index { return self.onboardingConsentSteps[index] }
        return nil
    }

    func getNextConsentStep(_ currentStep: OnboardingConsentStepIndex) -> OnboardingConsentStepIndex? {

        switch currentStep {
        case .en:
            if let exposureActiveState = exposureStateStream.currentExposureState?.activeState,
                exposureActiveState == .inactive(.bluetoothOff) {
                return .bluetooth
            }
            return .notifications
        case .bluetooth:
            return .notifications
        case .notifications:
            return nil
        }
    }

    func askEnableExposureNotifications(_ completion: @escaping ((_ exposureActiveState: ExposureActiveState) -> ())) {
        if let exposureActiveState = exposureStateStream.currentExposureState?.activeState,
            exposureActiveState != .notAuthorized {
            // already authorized
            completion(exposureActiveState)
            return
        }

        if let subscription = exposureStateSubscription {
            subscription.cancel()
        }

        exposureStateSubscription = exposureStateStream.exposureState.sink { [weak self] state in
            self?.exposureStateSubscription = nil

            completion(state.activeState)
        }

        exposureController.requestExposureNotificationPermission()
    }

    func goToBluetoothSettings(_ completion: @escaping (() -> ())) {

        if let settingsUrl = URL(string: "App-prefs:Bluetooth") {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }

        completion()
    }

    func askNotificationsAuthorization(_ completion: @escaping (() -> ())) {
        exposureController.requestPushNotificationPermission {
            completion()
        }
    }

    private let exposureStateStream: ExposureStateStreaming
    private let exposureController: ExposureControlling

    private var exposureStateSubscription: Cancellable?
}
