/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift
import UIKit
import CoreTelephony

enum CellularDataRestrictedState {
    case notRestricted
    case restricted
    case restrictedStateUnknown
    
    fileprivate static func fromCTRestrictedState(_ state: CTCellularDataRestrictedState) -> CellularDataRestrictedState {
        switch state {
        case .restrictedStateUnknown:
            return .restrictedStateUnknown
        case .restricted:
            return .restricted
        case .notRestricted:
            return .notRestricted
        @unknown default:
            return .restrictedStateUnknown
        }
    }
}

/// @mockable
protocol CellularDataStreaming {
    var restrictedState: BehaviorSubject<CellularDataRestrictedState> { get }
}

protocol CTCellularDataProtocol {
    var cellularDataRestrictionDidUpdateNotifier: CellularDataRestrictionDidUpdateNotifier? { get set }
    var restrictedState: CTCellularDataRestrictedState { get }
}

extension CTCellularData: CTCellularDataProtocol {}

final class CellularDataStream: CellularDataStreaming {

    private var cellularData: CTCellularDataProtocol
    
    init(cellularData: CTCellularDataProtocol = CTCellularData()) {
        self.cellularData = cellularData
        self.restrictedState = BehaviorSubject<CellularDataRestrictedState>(value: .fromCTRestrictedState(cellularData.restrictedState))
        self.cellularData.cellularDataRestrictionDidUpdateNotifier = { [weak self] state in
            self?.updateSubject()
        }
    }

    private func updateSubject() {
        restrictedState.onNext(.fromCTRestrictedState(cellularData.restrictedState))
    }

    // MARK: - InterfaceOrientationStreaming

    var restrictedState: BehaviorSubject<CellularDataRestrictedState>
}
