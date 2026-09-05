//
//  AppDirectories.swift
//  Qualverum
//
//  Created by Andrew Wallace on 05/09/26.
//

import Foundation

enum AppDirectories {
    static let root: URL = {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        .appending(
            path: "Qualverum",
            directoryHint: .isDirectory
        )
    }()

    static let documents =
        root.appending(
            path: "Documents",
            directoryHint: .isDirectory
        )

    static let rag =
        root.appending(
            path: "RAG",
            directoryHint: .isDirectory
        )

    static let workspace =
        root.appending(
            path: "workspace.json"
        )
}
