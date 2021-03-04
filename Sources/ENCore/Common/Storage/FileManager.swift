/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable(history: removeItem = true;createDirectory=true)
protocol FileManaging {
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
    func fileExists(atPath path: String) -> Bool
    func removeItem(at URL: URL) throws
    func removeItem(atPath path: String) throws
    func moveItem(at srcURL: URL, to dstURL: URL) throws
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws
    func unzipItem(at sourceURL: URL, to destinationURL: URL, skipCRC32: Bool, progress: Progress?, preferredEncoding: String.Encoding?) throws
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL]
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]
}

extension FileManager: FileManaging {}
