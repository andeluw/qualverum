//
//  WorkspacePersistence.swift
//  Qualverum
//
//  Created by Andrew Wallace on 05/09/26.
//

import Foundation

struct WorkspacePersistence {
    let url: URL

    init(
        url: URL = AppDirectories.workspace
    ) {
        self.url = url
    }

    func loadTenders() throws -> [Tender] {
        guard
            FileManager.default.fileExists(
                atPath: url.path
            )
        else {
            return []
        }

        let data = try Data(
            contentsOf: url
        )

        return try JSONDecoder().decode(
            [Tender].self,
            from: data
        )
    }
    func saveTenders(_ tenders: [Tender]) throws {
        let directoryURL =
            url.deletingLastPathComponent()

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let data = try JSONEncoder().encode(
            tenders
        )

        try data.write(
            to: url,
            options: .atomic
        )
    }
}
