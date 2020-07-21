/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import UIKit

/// @mockable
protocol OnboardingConsentManaging {
    var onboardingConsentSteps: [OnboardingConsentStep] { get }

    func getStep(_ index: Int) -> OnboardingConsentStep?
    func getNextConsentStep(_ currentStep: OnboardingConsentStepIndex, completion: @escaping (OnboardingConsentStepIndex?) -> ())

    func askEnableExposureNotifications(_ completion: @escaping ((_ exposureActiveState: ExposureActiveState) -> ()))
    func goToBluetoothSettings(_ completion: @escaping (() -> ()))
    func askNotificationsAuthorization(_ completion: @escaping (() -> ()))
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
                title: .consentStep1Title,
                content: "",
                image: nil,
                animationName: nil,
                summarySteps: [
                    OnboardingConsentSummaryStep(
                        theme: theme,
                        title: .consentStep1Summary1,
                        image: .bluetoothShield
                    ),
                    OnboardingConsentSummaryStep(
                        theme: theme,
                        title: .consentStep1Summary2,
                        image: .lockShield
                    ),
                    OnboardingConsentSummaryStep(
                        theme: theme,
                        title: .consentStep1Summary3,
                        image: .lockShield
                    )
                ],
                primaryButtonTitle: .consentStep1PrimaryButton,
                secondaryButtonTitle: .consentStep1SecondaryButton,
                hasNavigationBarSkipButton: true
            )
        )

        onboardingConsentSteps.append(
            OnboardingConsentStep(
                step: .bluetooth,
                theme: theme,
                title: .consentStep2Title,
                content: .consentStep2Content,
                image: .pleaseTurnOnBluetooth,
                animationName: nil,
                summarySteps: nil,
                primaryButtonTitle: .consentStep2PrimaryButton,
                secondaryButtonTitle: .consentStep2SecondaryButton,
                hasNavigationBarSkipButton: true
            )
        )

        onboardingConsentSteps.append(
            OnboardingConsentStep(
                step: .notifications,
                theme: theme,
                title: .consentStep3Title,
                content: .consentStep3Content,
                image: .pleaseTurnOnNotifications,
                animationName: nil,
                summarySteps: nil,
                primaryButtonTitle: .consentStep3PrimaryButton,
                secondaryButtonTitle: .consentStep3SecondaryButton,
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

    func getNextConsentStep(_ currentStep: OnboardingConsentStepIndex, completion: @escaping (OnboardingConsentStepIndex?) -> ()) {
        switch currentStep {
        case .en:
            exposureStateStream
                .exposureState
                .filter { $0.activeState != .notAuthorized }
                .first()
                .sink { value in
                    switch value.activeState {
                    case .inactive(.bluetoothOff):
                        completion(.bluetooth)
                    default:
                        completion(.notifications)
                    }
                }
                .store(in: &disposeBag)
        case .bluetooth:
            completion(.notifications)
        case .notifications:
            completion(nil)
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

        exposureStateSubscription = exposureStateStream
            .exposureState
            .filter { $0.activeState != .notAuthorized }
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

    private let exposureStateStream: ExposureStateStreaming
    private let exposureController: ExposureControlling

    private var exposureStateSubscription: Cancellable?
}
