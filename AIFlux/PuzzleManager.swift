import Foundation
import SwiftUI
import Combine

@MainActor
final class PuzzleManager: ObservableObject {
    @Published private(set) var currentPuzzle: Puzzle?
    @Published private(set) var assembledWord: String = ""
    @Published private(set) var selectedTileIDs: [UUID] = []
    @Published private(set) var score: Int = 0
    @Published private(set) var combo: Int = 0
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var roundResult: RoundResult?
    @Published private(set) var isRoundTransitioning: Bool = false
    @Published private(set) var generationStatus: String = "Using Foundation Model"
    @Published private(set) var debugLines: [String] = []
    @Published private(set) var puzzleNumber: Int = 0

    private let aiService: AIServiceProtocol
    private let randomLetters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init)

    init(aiService: AIServiceProtocol) {
        self.aiService = aiService
    }

    convenience init() {
        self.init(aiService: AIService())
    }

    func startGame() async {
        await loadNextPuzzle()
    }

    func loadNextPuzzle() async {
        let requestID = UUID().uuidString.prefix(8)
        appendDebug("[\(requestID)] Requesting puzzle from Foundation Model")
        isLoading = true
        roundResult = nil
        assembledWord = ""
        selectedTileIDs = []

        let seed: PuzzleSeed
        do {
            let start = Date()
            seed = try await aiService.generatePuzzle()
            let elapsed = Date().timeIntervalSince(start)
            generationStatus = "Foundation Model OK • \(String(format: "%.2fs", elapsed))"
            appendDebug("[\(requestID)] Success \(String(format: "%.2fs", elapsed))")
            appendDebug("[\(requestID)] clue: \(seed.clue)")
            appendDebug("[\(requestID)] word: \(seed.word)")
        } catch {
            isLoading = false
            if let localizedError = error as? LocalizedError {
                generationStatus = localizedError.errorDescription ?? "Puzzle generation failed."
            } else {
                generationStatus = "Puzzle generation failed."
            }
            appendDebug("[\(requestID)] Error: \(generationStatus)")
            return
        }

        currentPuzzle = makePuzzle(from: seed)
        puzzleNumber += 1
        appendDebug("[\(requestID)] Loaded puzzle #\(puzzleNumber)")
        isLoading = false
    }

    func selectLetter(tileID: UUID) {
        guard
            let puzzle = currentPuzzle,
            !isRoundTransitioning,
            let tile = puzzle.letters.first(where: { $0.id == tileID }),
            !selectedTileIDs.contains(tileID)
        else {
            return
        }

        let nextIndex = selectedTileIDs.count
        guard nextIndex < puzzle.word.count else {
            return
        }

        let expectedCharacter = puzzle.word[puzzle.word.index(puzzle.word.startIndex, offsetBy: nextIndex)]
        let selectedCharacter = Character(tile.value)

        selectedTileIDs.append(tileID)
        assembledWord.append(selectedCharacter)

        if selectedCharacter != expectedCharacter {
            roundResult = .incorrect
            isRoundTransitioning = true
            combo = 0

            Task {
                try? await Task.sleep(for: .milliseconds(700))
                await MainActor.run {
                    assembledWord = ""
                    selectedTileIDs = []
                    roundResult = nil
                    isRoundTransitioning = false
                }
            }
            return
        }

        if assembledWord == puzzle.word {
            roundResult = .correct
            isRoundTransitioning = true
            combo += 1
            score += 100 * max(1, combo)

            Task {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    self.roundResult = nil
                    self.isRoundTransitioning = false
                }
                await loadNextPuzzle()
            }
        }
    }

    func shuffleLetters() {
        guard let puzzle = currentPuzzle, !isRoundTransitioning else {
            return
        }

        let reshuffled = puzzle.letters.shuffled().enumerated().map { index, tile in
            LetterTile(id: tile.id, value: tile.value, index: index)
        }

        currentPuzzle = Puzzle(category: puzzle.category, clue: puzzle.clue, word: puzzle.word, letters: reshuffled)
        assembledWord = ""
        selectedTileIDs = []
        combo = max(0, combo - 1)
    }

    func useHint() {
        guard let puzzle = currentPuzzle, !isRoundTransitioning else {
            return
        }

        let nextIndex = selectedTileIDs.count
        guard nextIndex < puzzle.word.count else {
            return
        }

        let targetCharacter = String(puzzle.word[puzzle.word.index(puzzle.word.startIndex, offsetBy: nextIndex)])
        guard let tile = puzzle.letters.first(where: { $0.value == targetCharacter && !selectedTileIDs.contains($0.id) }) else {
            return
        }

        selectedTileIDs.append(tile.id)
        assembledWord.append(Character(targetCharacter))
        score = max(0, score - 20)

        if assembledWord == puzzle.word {
            roundResult = .correct
            isRoundTransitioning = true
            combo += 1
            score += 100 * max(1, combo)

            Task {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    self.roundResult = nil
                    self.isRoundTransitioning = false
                }
                await loadNextPuzzle()
            }
        }
    }

    func removeLastSelection() {
        guard !selectedTileIDs.isEmpty, !isRoundTransitioning else {
            return
        }

        selectedTileIDs.removeLast()
        if !assembledWord.isEmpty {
            assembledWord.removeLast()
        }
    }

    private func makePuzzle(from seed: PuzzleSeed) -> Puzzle {
        let normalizedWord = seed.word.uppercased().components(separatedBy: CharacterSet.letters.inverted).joined()
        let safeWord = normalizedWord.count >= 3 ? normalizedWord : "MOON"

        let wordLetters = safeWord.map { String($0) }
        let extraCount = Int.random(in: 3...5)
        let extras = (0..<extraCount).map { _ in randomLetters.randomElement() ?? "A" }
        let pool = (wordLetters + extras).shuffled()

        let tiles = pool.enumerated().map { index, letter in
            LetterTile(id: UUID(), value: letter, index: index)
        }

        let safeCategory = seed.category.isEmpty ? "One Word Substitution" : seed.category
        return Puzzle(category: safeCategory, clue: seed.clue, word: safeWord, letters: tiles)
    }

    private func appendDebug(_ line: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        debugLines.append("\(timestamp) \(line)")
        if debugLines.count > 14 {
            debugLines.removeFirst(debugLines.count - 14)
        }
        print("[PuzzleManager] \(line)")
    }
}
