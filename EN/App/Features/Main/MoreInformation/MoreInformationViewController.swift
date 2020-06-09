/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

protocol MoreInformationRouting: Routing {
    // TODO: Add any routing functions that are called from the ViewController
    // func routeToChild()
}

final class MoreInformationViewController: ViewController, MoreInformationViewControllable {
    
    // MARK: - MoreInformationViewControllable
    
    weak var router: MoreInformationRouting?
    
    // TODO: Validate whether you need the below functions and remove or replace
    //       them as desired.
    
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        present(viewController.uiviewController,
                animated: animated,
                completion: completion)
    }
    
    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        viewController.uiviewController.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - Private
    
    // TODO: Anything private goes here
}
