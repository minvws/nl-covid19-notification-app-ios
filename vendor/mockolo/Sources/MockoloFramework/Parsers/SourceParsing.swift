
//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

public enum DeclType {
    case protocolType, classType, other, all
}

public protocol SourceParsing {
    
    /// Parses processed decls (mock classes) and calls a completion block
    /// @param paths File paths containing processed mocks
    /// @param fileMacro: File level macro
    /// @param completion:The block to be executed on completion
    func parseProcessedDecls(_ paths: [String],
                             fileMacro: String?,
                             completion: @escaping ([Entity], ImportMap?) -> ())
    
    /// Parses decls (protocol, class) with annotations (/// @mockable) and calls a completion block
    /// @param paths File/dir paths containing types with mock annotation
    /// @param isDirs:True if paths are dir paths
    /// @param exclusionSuffixess List of file suffixes to exclude when processing
    /// @param annotation The mock annotation
    /// @param fileMacro: File level macro
    /// @param declType: The declaration type, e.g. protocol, class.
    /// @param completion:The block to be executed on completion
    func parseDecls(_ paths: [String]?,
                    isDirs: Bool,
                    exclusionSuffixes: [String]?,
                    annotation: String,
                    fileMacro: String?,
                    declType: DeclType,
                    completion: @escaping ([Entity], ImportMap?) -> ())
}
