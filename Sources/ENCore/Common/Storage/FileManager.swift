/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol FileManaging {
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
    func fileExists(atPath path: String) -> Bool
    func removeItem(at URL: URL) throws
    func removeItem(atPath path: String) throws
    func moveItem(at srcURL: URL, to dstURL: URL) throws
}

extension FileManager: FileManaging {}
