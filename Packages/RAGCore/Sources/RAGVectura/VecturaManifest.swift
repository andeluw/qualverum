//
//  VecturaManifest.swift
//  RAGCore
//
//  Created by Andrew Wallace on 05/09/26.
//

struct VecturaManifest: Codable, Sendable {
    var version = 1
    var chunks: [VecturaChunkRecord] = []
}
