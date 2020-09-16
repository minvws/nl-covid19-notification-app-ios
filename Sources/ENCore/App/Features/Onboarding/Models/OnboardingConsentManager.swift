/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import CoreBluetooth
import ENFoundation
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
}

final class OnboardingConsentManager: OnboardingConsentManaging {

    var onboardingConsentSteps: [OnboardingConsentStep] = []
    private var disposeBag = Set<AnyCancellable>()

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

    deinit {
        disposeBag.forEach { $0.cancel() }
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
                .first()
                .sink { value in
                    switch value.activeState {
                    case .inactive(.bluetoothOff):
                        completion(.bluetooth)
                    default:
                        completion(.share)
                    }
                }
                .store(in: &disposeBag)
        case .bluetooth:
            completion(.share)
        case .share:
            completion(nil)
        }
    }

    func isNotificationAuthorizationAsked(_ completion: @escaping (Bool) -> ()) {
        exposureStateStream
            .exposureState
            .first()
            .sink { value in
                if value.activeState == .notAuthorized {
                    completion(false)
                } else {
                    completion(true)
                }
            }
            .store(in: &disposeBag)
    }

    func isBluetoothEnabled(_ completion: @escaping (Bool) -> ()) {
        if let exposureActiveState = exposureStateStream.currentExposureState?.activeState {
            completion(exposureActiveState == .inactive(.bluetoothOff) ? false : true)
        }
    }

    func askEnableExposureNotifications(_ completion: @escaping ((_ exposureActiveState: ExposureActiveState) -> ())) {
        if let exposureActiveState = exposureStateStream.currentExposureState?.activeState,
            exposureActiveState != .notAuthorized, exposureActiveState != .inactive(.disabled) {
            // already authorized
            completion(exposureActiveState)
            return
        }

        if let subscription = exposureStateSubscription {
            subscription.cancel()
        }

        exposureStateSubscription = exposureStateStream
            .exposureState
            .filter { $0.activeState != .notAuthorized && $0.activeState != .inactive(.disabled) }
            .sink { [weak self] state in
                self?.exposureStateSubscription = nil

                completion(state.activeState)
            }

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

    private let exposureStateStream: ExposureStateStreaming
    private let exposureController: ExposureControlling

    private var exposureStateSubscription: Cancellable?
}
