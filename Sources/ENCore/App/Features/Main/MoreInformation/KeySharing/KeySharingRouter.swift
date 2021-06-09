/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol KeySharingViewControllable: ViewControllable {
    var router: KeySharingRouting? { get set }
    func push(viewController: ViewControllable, animated: Bool)
    func dismiss(viewController: ViewControllable)
}

final class KeySharingRouter: Router<KeySharingViewControllable>, KeySharingRouting, ShareKeyViaPhoneListener {
    
    // MARK: - Initialisation

    init(listener: KeySharingListener,
         viewController: KeySharingViewControllable,
         shareKeyViaPhoneBuilder: ShareKeyViaPhoneBuildable,
         featureFlagController: FeatureFlagControlling) {
        self.listener = listener
        self.shareKeyViaPhoneBuilder = shareKeyViaPhoneBuilder
        self.featureFlagController = featureFlagController
        super.init(viewController: viewController)

        viewController.router = self
    }
    
    // MARK: - KeySharingRouting
    
    func viewDidLoad() {
        if !featureFlagController.isFeatureFlagEnabled(feature: .independentKeySharing) {
            routeToShareKeyViaGGD(animated: false, withBackButton: false)
        }
    }
    
    func routeToShareKeyViaGGD(animated: Bool, withBackButton: Bool) {
        let shareKeyViewController = self.shareKeyViaPhoneBuilder.build(withListener: self, withBackButton: withBackButton).viewControllable
        viewController.push(viewController: shareKeyViewController, animated: animated)
    }
    
    func routeToShareKeyViaWebsite() {
        //TODO: Route to key sharing via website
    }
    
    func keySharingWantsDismissal(shouldDismissViewController: Bool) {
        listener?.keySharingWantsDismissal(shouldDismissViewController: shouldDismissViewController)
    }
        
    // MARK: - InfectedListener
    
    func infectedWantsDismissal(shouldDismissViewController: Bool) {        
        // infected flow finished or cancelled. Signal back to listener to dismiss all presented viewcontrollers
        listener?.keySharingWantsDismissal(shouldDismissViewController: shouldDismissViewController)
    }
    
    // MARK: - Private

    private weak var listener: KeySharingListener?
    private let shareKeyViaPhoneBuilder: ShareKeyViaPhoneBuildable
    private let featureFlagController: FeatureFlagControlling
}
