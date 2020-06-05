/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

class OnboardingStepViewAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let fromVC: OnboardingStepViewController
    private let toVC: OnboardingStepViewController
    private let push: Bool

    init(fromVC: OnboardingStepViewController, toVC: OnboardingStepViewController, push: Bool) {
        self.fromVC = fromVC
        self.toVC = toVC
        self.push = push
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Fade-in new VC
        toVC.view.alpha = 0.0

        // Progress bar animation
        toVC.progressView.progress = fromVC.progress
        toVC.progressView.layoutIfNeeded()

        fromVC.progressView.progress = toVC.progress
        toVC.progressView.progress = toVC.progress

        // Set up sliding animation
        let toX: CGFloat = push ? 170 : -170
        let fromX: CGFloat = push ? -170 : 170

        fromVC.viewsAnimatedTransition.forEach { $0.transform = CGAffineTransform(translationX: 0, y: 0) }
        toVC.viewsAnimatedTransition.forEach { $0.transform = CGAffineTransform(translationX: toX, y: 0) }

        transitionContext.containerView.addSubview(toVC.view)

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       animations: {
                        self.toVC.view.alpha = 1.0

                        self.fromVC.progressView.layoutIfNeeded()
                        self.toVC.progressView.layoutIfNeeded()

                        self.fromVC.viewsAnimatedTransition.forEach {
                            $0.transform = CGAffineTransform(translationX: fromX, y: 0)
                        }
                        self.toVC.viewsAnimatedTransition.forEach {
                            $0.transform = CGAffineTransform(translationX: 0, y: 0)
                        }
        },
                       completion: { _ in
                        self.fromVC.progressView.progress = self.fromVC.progress
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
