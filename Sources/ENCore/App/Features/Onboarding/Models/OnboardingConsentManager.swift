/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import RxSwift
import UIKit

/// @mockable
protocol OnboardingConsentManaging {
    var onboardingConsentSteps: [OnboardingConsentStep] { get }

    func getStep(_ index: Int) -> OnboardingConsentStep?
    func getNextConsentStep(_ currentStep: OnboardingConsentStep.Index, skippedCurrentStep: Bool, completion: @escaping (OnboardingConsentStep.Index?) -> ())
    func isBluetoothEnabled(_ completion: @escaping (Bool) -> ())
    func askEnableExposureNotifications(_ completion: @escaping ((_ exposureActiveState: ExposureActiveState) -> ()))
    func goToBluetoothSettings(_ completion: @escaping (() -> ()))
    func askNotificationsAuthorization(_ completion: @escaping (() -> ()))
    func getAppStoreUrl(_ completion: @escaping ((String?) -> ()))
    func isNotificationAuthorizationAsked(_ completion: @escaping (Bool) -> ())
    func didCompleteConsent()
}

final class OnboardingConsentManager: OnboardingConsentManaging, Logging {

    var onboardingConsentSteps: [OnboardingConsentStep] = []
    private var disposeBag = DisposeBag()

    init(exposureStateStream: ExposureStateStreaming,
         exposureController: ExposureControlling,
         theme: Theme) {

        self.exposureStateStream = exposureStateStream
        self.exposureController = exposureController

        onboardingConsentSteps.append(
            OnboardingConsentStep(
                step: .en,
                theme: theme,
                title: .onboardingPermissionsTitle,
                content: .onboardingPermissionsDescription,
                bulletItems: [.onboardingPermissionsDescriptionList1, .onboardingPermissionsDescriptionList2],
                illustration: .animation(named: "permission", repeatFromFrame: 100, defaultFrame: 56),
                primaryButtonTitle: .onboardingPermissionsPrimaryButton,
                secondaryButtonTitle: .onboardingPermissionsSecondaryButton,
                hasNavigationBarSkipButton: true
            )
        )

        onboardingConsentSteps.append(
            OnboardingConsentStep(
                step: .bluetooth,
                theme: theme,
                title: .consentStep2Title,
                content: .consentStep2Content,
                illustration: .image(image: .pleaseTurnOnBluetooth),
                primaryButtonTitle: .consentStep2PrimaryButton,
                secondaryButtonTitle: nil,
                hasNavigationBarSkipButton: true
            )
        )

        /* Disabled For 57828
         onboardingConsentSteps.append(
             OnboardingConsentStep(
                 step: .notifications,
                 theme: theme,
                 title: .consentStep3Title,
                 content: .consentStep3Content,
                 illustration: .image(image: .pleaseTurnOnNotifications),
                 summarySteps: nil,
                 primaryButtonTitle: .consentStep3PrimaryButton,
                 secondaryButtonTitle: .consentStep3SecondaryButton,
                 hasNavigationBarSkipButton: true
             )
         )
         */

        onboardingConsentSteps.append(
            OnboardingConsentStep(
                step: .share,
                theme: theme,
                title: .consentStep4Title,
                content: .consentStep4Content,
                illustration: .animation(named: "share", repeatFromFrame: 31, defaultFrame: 35),
                primaryButtonTitle: .consentStep4PrimaryButton,
                secondaryButtonTitle: .consentStep4SecondaryButton,
                hasNavigationBarSkipButton: true
            )
        )
    }

    // MARK: - Functions

    func getStep(_ index: Int) -> OnboardingConsentStep? {
        if self.onboardingConsentSteps.count > index { return self.onboardingConsentSteps[index] }
        return nil
    }

    func getNextConsentStep(_ currentStep: OnboardingConsentStep.Index, skippedCurrentStep: Bool, completion: @escaping (OnboardingConsentStep.Index?) -> ()) {
        switch currentStep {
        case .en:
            exposureStateStream
                .exposureState
                .filter { $0.activeState != .notAuthorized || skippedCurrentStep }
                .take(1)
                .subscribe(onNext: { value in
                    switch value.activeState {
                    case .inactive(.bluetoothOff):
                        completion(.bluetooth)
                    default:
                        completion(.share)
                    }
                })
                .disposed(by: disposeBag)
        case .bluetooth:
            completion(.share)
        case .share:
            completion(nil)
        }
    }

    func isNotificationAuthorizationAsked(_ completion: @escaping (Bool) -> ()) {
        exposureStateStream
            .exposureState
            .take(1)
            .subscribe(onNext: { value in
                if value.activeState == .notAuthorized || value.activeState == .inactive(.disabled) {
                    completion(false)
                } else {
                    completion(true)
                }
            })
            .disposed(by: disposeBag)
    }

    func isBluetoothEnabled(_ completion: @escaping (Bool) -> ()) {
        if let exposureActiveState = exposureStateStream.currentExposureState?.activeState {
            completion(exposureActiveState == .inactive(.bluetoothOff) ? false : true)
        }
    }

    func askEnableExposureNotifications(_ completion: @escaping ((_ exposureActiveState: ExposureActiveState) -> ())) {
        logDebug("`askEnableExposureNotifications` started")
        if let exposureActiveState = exposureStateStream.currentExposureState?.activeState,
            exposureActiveState != .notAuthorized, exposureActiveState != .inactive(.disabled) {
            logDebug("`askEnableExposureNotifications` already authorised")
            // already authorized
            completion(exposureActiveState)
            return
        }

        if let subscription = exposureStateSubscription {
            subscription.dispose()
        }

        exposureStateSubscription = exposureStateStream
            .exposureState
            .filter { $0.activeState != .notAuthorized && $0.activeState != .inactive(.disabled) }
            .subscribe(onNext: { [weak self] state in
                self?.exposureStateSubscription = nil
                self?.logDebug("`askEnableExposureNotifications` active state changed to \(state.activeState)")

                completion(state.activeState)
            })

        logDebug("`askEnableExposureNotifications` calling `requestExposureNotificationPermission`")
        exposureController.requestExposureNotificationPermission(nil)
    }

    func goToBluetoothSettings(_ completion: @escaping (() -> ())) {

        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
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

    func getAppStoreUrl(_ completion: @escaping ((String?) -> ())) {
        exposureController.getAppVersionInformation { data in
            completion(data?.appStoreURL)
        }
    }

    func didCompleteConsent() {
        exposureController.didCompleteOnboarding = true

        // Mark all announcements that were made during the onboarding process as "seen"
        exposureController.seenAnnouncements = [.interopAnnouncement]
    }

    private let exposureStateStream: ExposureStateStreaming
    private let exposureController: ExposureControlling

    private var exposureStateSubscription: Disposable?
}
