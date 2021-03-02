/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable(history: removeItem = true)
protocol FileManaging {
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
    func fileExists(atPath path: String) -> Bool
    func removeItem(at URL: URL) throws
    func removeItem(atPath path: String) throws
    func moveItem(at srcURL: URL, to dstURL: URL) throws
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws
    func unzipItem(at sourceURL: URL, to destinationURL: URL, skipCRC32: Bool, progress: Progress?, preferredEncoding: String.Encoding?) throws
    var manager: FileManager { get }
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws
}

extension FileManager: FileManaging {

    var manager: FileManager {
        return FileManager.default
    }

    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws {
        try manager.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: nil)
    }
}
