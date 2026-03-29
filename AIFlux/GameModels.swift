import Foundation

struct Puzzle: Identifiable, Equatable {
    let id = UUID()
    let category: String
    let clue: String
    let word: String
    let letters: [LetterTile]
}

struct LetterTile: Identifiable, Hashable {
    let id: UUID
    let value: String
    let index: Int
}

enum RoundResult {
    case correct
    case incorrect
}
