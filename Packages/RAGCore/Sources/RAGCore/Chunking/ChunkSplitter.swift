//
//  ChunkSplitter.swift
//  RAGCore
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation
import NaturalLanguage

struct ChunkSplitter: Sendable {
    let maxWords: Int

    init(maxWords: Int) {
        self.maxWords = maxWords
    }

    func split(_ text: String) -> [String] {
        let paragraphs =
            text
            .components(separatedBy: "\n\n")
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter {
                !$0.isEmpty
            }

        var chunks: [String] = []
        var current: [String] = []
        var currentWordCount = 0

        for paragraph in paragraphs {
            let paragraphWordCount = wordCount(paragraph)

            if paragraphWordCount > maxWords {
                if !current.isEmpty {
                    chunks.append(
                        current.joined(separator: "\n\n")
                    )

                    current = []
                    currentWordCount = 0
                }

                chunks.append(
                    contentsOf: splitOversized(paragraph)
                )

                continue
            }

            if currentWordCount + paragraphWordCount > maxWords {
                chunks.append(
                    current.joined(separator: "\n\n")
                )

                current = []
                currentWordCount = 0
            }

            current.append(paragraph)
            currentWordCount += paragraphWordCount
        }

        if !current.isEmpty {
            chunks.append(
                current.joined(separator: "\n\n")
            )
        }

        return chunks
    }

    private func splitOversized(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [String] = []

        tokenizer.enumerateTokens(
            in: text.startIndex..<text.endIndex
        ) { range, _ in
            let sentence = text[range]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !sentence.isEmpty {
                sentences.append(sentence)
            }

            return true
        }

        var chunks: [String] = []
        var current: [String] = []
        var currentWordCount = 0

        for sentence in sentences {
            let sentenceWordCount = wordCount(sentence)

            if sentenceWordCount > maxWords {
                if !current.isEmpty {
                    chunks.append(
                        current.joined(separator: " ")
                    )

                    current = []
                    currentWordCount = 0
                }

                chunks.append(
                    contentsOf: splitWords(sentence)
                )

                continue
            }

            if currentWordCount + sentenceWordCount > maxWords {
                chunks.append(
                    current.joined(separator: " ")
                )

                current = []
                currentWordCount = 0
            }

            current.append(sentence)
            currentWordCount += sentenceWordCount
        }

        if !current.isEmpty {
            chunks.append(
                current.joined(separator: " ")
            )
        }

        return chunks
    }

    private func splitWords(_ text: String) -> [String] {
        let words = text.split(
            whereSeparator: \.isWhitespace
        )

        return stride(
            from: 0,
            to: words.count,
            by: maxWords
        ).map { start in
            let end = min(
                start + maxWords,
                words.count
            )

            return words[start..<end]
                .map(String.init)
                .joined(separator: " ")
        }
    }

    private func wordCount(_ text: String) -> Int {
        text.split(
            whereSeparator: \.isWhitespace
        ).count
    }
}
