import Foundation

struct TextChunk {
    let range: Range<String.Index>
    let text: String
}

/// Splits long inputs into smaller pieces that fit within the model token budget.
struct TextChunker {
    let maxCharacters: Int

    init(maxCharacters: Int = 2048) {
        self.maxCharacters = maxCharacters
    }

    func chunks(for text: String) -> [TextChunk] {
        guard text.count > maxCharacters else {
            return [TextChunk(range: text.startIndex..<text.endIndex, text: text)]
        }

        var chunks: [TextChunk] = []
        var start = text.startIndex
        while start < text.endIndex {
            let end = text.index(start, offsetBy: maxCharacters, limitedBy: text.endIndex) ?? text.endIndex
            let chunkRange = start..<end
            let chunkText = String(text[chunkRange])
            chunks.append(TextChunk(range: chunkRange, text: chunkText))
            start = end
        }
        return chunks
    }
}
