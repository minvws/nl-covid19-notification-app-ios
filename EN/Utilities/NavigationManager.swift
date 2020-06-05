/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

///
/// Class that enables custom animations in the UINavigationManager
/// Facilitates the animations used in the Onboarding screens
///
class NavigationManager: NSObject, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    private var interactionController: UIPercentDrivenInteractiveTransition?

    /// Gesture recognizer used for custom back-navigation swipes from the left edge of the screen
    private let edgeGestureRecognizer = UIScreenEdgePanGestureRecognizer()

    private weak var navigationController: NavigationController?

    init(controller: NavigationController) {
        super.init()

        self.navigationController = controller
        self.edgeGestureRecognizer.addTarget(self, action: #selector(handleSwipeFromLeftEdge))
        edgeGestureRecognizer.edges = .left
        edgeGestureRecognizer.delegate = self
        controller.view.addGestureRecognizer(edgeGestureRecognizer)

        controller.delegate = self
        controller.interactivePopGestureRecognizer?.delegate = self

    }

    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let fromVC = fromVC as? OnboardingStepViewController,
              let toVC = toVC as? OnboardingStepViewController {
            switch operation {
            case .push:
                return OnboardingStepViewAnimator(fromVC: fromVC, toVC: toVC, push: true)
            case .pop:
                return OnboardingStepViewAnimator(fromVC: fromVC, toVC: toVC, push: false)
            default:
                break
            }
        }
        return nil
    }

    func navigationController(_ navigationController: UINavigationController,
                              interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }

    ///
    /// This callback enables the use of the original interactivePopGestureRecognizer
    /// and our own custom edgeGestureRecognizer
    /// This allows the use of both normal and custom back navigation animations in the UINavigationViewController
    ///
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        guard let navigationController = navigationController,
            navigationController.viewControllers.count >= 2 else {
                return false
        }
        let fromVC = navigationController.viewControllers.last
        let toVC = navigationController.viewControllers[navigationController.viewControllers.count - 2]

        if fromVC is OnboardingStepViewController && toVC is OnboardingStepViewController {
            if gestureRecognizer == edgeGestureRecognizer {
                return true
            }
        } else if gestureRecognizer == navigationController.interactivePopGestureRecognizer {
            return true
        }
        return false
    }

    @objc func handleSwipeFromLeftEdge(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard let gestureView = gestureRecognizer.view else {
            return
        }

        let translate = gestureRecognizer.translation(in: gestureRecognizer.view)
        let percent = translate.x / gestureView.bounds.size.width

        switch gestureRecognizer.state {
        case .began:
            self.interactionController = UIPercentDrivenInteractiveTransition()
            navigationController?.popViewController(animated: true)

        case .changed:
            self.interactionController?.update(percent)

        case .ended:
            let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)
            if percent > 0.5 || velocity.x > 0 {
                self.interactionController?.finish()
            } else {
                self.interactionController?.cancel()
            }
            self.interactionController = nil

        default:
            break
        }
    }
}
