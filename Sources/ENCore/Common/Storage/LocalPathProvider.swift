/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

enum LocalFolder {
    case temporary
    case documents
    case cache
    case exposureKeySets
}

/// @mockable
protocol LocalPathProviding {
    func path(for folder: LocalFolder) -> URL?
    var temporaryDirectoryUrl: URL { get }
}

final class LocalPathProvider: LocalPathProviding, Logging {

    init(fileManager: FileManaging) {
        self.fileManager = fileManager
    }

    func path(for folder: LocalFolder) -> URL? {
        let path: URL?

        switch folder {
        case .cache:
            path = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        case .documents:
            path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        case .temporary:
            path = fileManager.urls(for: .itemReplacementDirectory, in: .userDomainMask).first
        case .exposureKeySets:
            path = self.path(for: .documents)?.appendingPathComponent("exposureKeySets")
        }

        guard let finalPath = path else {
            return nil
        }

        return createFolder(with: finalPath) ? finalPath : nil
    }

    var temporaryDirectoryUrl: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory(),
                   isDirectory: true)
    }

    // MARK: - Private

    private func createFolder(with url: URL) -> Bool {
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            return false
        }
    }

    private let fileManager: FileManaging
}
