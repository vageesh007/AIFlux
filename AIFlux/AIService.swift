import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct PuzzleSeed: Sendable {
    let category: String
    let clue: String
    let word: String
}

enum AIServiceError: Error {
    case frameworkUnavailable
    case modelUnavailable(reason: String)
    case invalidOutput
}

protocol AIServiceProtocol: Sendable {
    func generatePuzzle() async throws -> PuzzleSeed
}

actor AIService: AIServiceProtocol {
    private var recentSignatures: [String] = []
    private let maxRecentSignatures = 20

    func generatePuzzle() async throws -> PuzzleSeed {
        print("[AIService] generatePuzzle() called")
        #if canImport(FoundationModels)
        if #available(iOS 18.0, *) {
            let requestID = UUID().uuidString.prefix(8)
            let maxAttempts = 6
            var lastSeed: PuzzleSeed?

            for attempt in 1...maxAttempts {
                let seed = try await FoundationModelPuzzleService.generatePuzzle(
                    requestID: String(requestID),
                    attempt: attempt,
                    avoidSignatures: Array(recentSignatures.prefix(8))
                )
                let signature = signature(for: seed)
                lastSeed = seed

                if !recentSignatures.contains(signature) {
                    remember(signature)
                    print("[AIService] Accepted unique puzzle on attempt \(attempt)")
                    return seed
                }

                print("[AIService] Duplicate puzzle on attempt \(attempt), retrying...")
            }

            if let lastSeed {
                let lastSignature = signature(for: lastSeed)
                remember(lastSignature)
                print("[AIService] Returning last attempt after retries")
                return lastSeed
            }

            throw AIServiceError.invalidOutput
        }
        #endif
        print("[AIService] FoundationModels framework unavailable on this runtime")
        throw AIServiceError.frameworkUnavailable
    }

    private func signature(for seed: PuzzleSeed) -> String {
        "\(seed.clue.lowercased())|\(seed.word.uppercased())"
    }

    private func remember(_ signature: String) {
        recentSignatures.append(signature)
        if recentSignatures.count > maxRecentSignatures {
            recentSignatures.removeFirst(recentSignatures.count - maxRecentSignatures)
        }
    }
}

#if canImport(FoundationModels)
@available(iOS 18.0, *)
@Generable(description: "A one word substitution puzzle")
private struct AIPuzzleResponse {
    @Guide(description: "Puzzle category label")
    var category: String

    @Guide(description: "A short clue phrase that describes something")
    var clue: String

    @Guide(description: "A single-word answer in uppercase letters")
    var word: String
}

@available(iOS 18.0, *)
private enum FoundationModelPuzzleService {
    static func generatePuzzle(
        requestID: String,
        attempt: Int,
        avoidSignatures: [String]
    ) async throws -> PuzzleSeed {
        let model = SystemLanguageModel.default
        let start = Date()
        print("[AIService] Checking model availability...")
        switch model.availability {
        case .available:
            print("[AIService] Model available")
            break
        case .unavailable(let reason):
            print("[AIService] Model unavailable: \(reason)")
            throw AIServiceError.modelUnavailable(reason: String(describing: reason))
        }

        let instructions = """
        You generate one-word substitution puzzles for a vocabulary game.
        Keep clues clear, school-friendly, and concise.
        MUST generate a fresh puzzle each time.
        Respond in U.S. English.
        """
        let avoidBlock = avoidSignatures.isEmpty ? "None" : avoidSignatures.joined(separator: "\n")
        let prompt = """
        Generate a one-word substitution puzzle.
        The puzzle must include:
        1) category: always \"One Word Substitution\"
        2) clue: a short phrase like \"A person who always thinks positive\"
        3) word: the single correct answer word in uppercase.
        4) Use a different semantic domain every time (profession, behavior, object, place, science, literature, emotion, law, medicine, education, travel, technology).
        5) DO NOT repeat any clue or answer from the disallowed list below.

        Request nonce: \(requestID)-\(attempt)
        Disallowed clue|word signatures:
        \(avoidBlock)

        Respond only in JSON with keys category, clue, and word.
        """

        let session = LanguageModelSession(model: model, instructions: instructions)
        print("[AIService] Sending request to Foundation Model...")
        let options = GenerationOptions(temperature: 0.92)
        let response = try await session.respond(to: prompt, generating: AIPuzzleResponse.self, options: options)

        let category = response.content.category.trimmingCharacters(in: .whitespacesAndNewlines)
        let clue = response.content.clue.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawWord = response.content.word.uppercased()
        let cleanedWord = rawWord.components(separatedBy: CharacterSet.letters.inverted).joined()

        guard !clue.isEmpty, cleanedWord.count >= 3 else {
            print("[AIService] Invalid output. clue='\(clue)', word='\(cleanedWord)'")
            throw AIServiceError.invalidOutput
        }

        let safeCategory = category.isEmpty ? "One Word Substitution" : category
        let elapsed = Date().timeIntervalSince(start)
        print("[AIService] Success in \(String(format: "%.2fs", elapsed)) | category='\(safeCategory)' clue='\(clue)' word='\(cleanedWord)'")
        return PuzzleSeed(category: safeCategory, clue: clue, word: cleanedWord)
    }
}
#endif

extension AIServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .frameworkUnavailable:
            return "Foundation Models requires iOS 18+ and Apple Intelligence support."
        case .modelUnavailable(let reason):
            return "Foundation Model unavailable: \(reason). Check Apple Intelligence settings on a supported device."
        case .invalidOutput:
            return "Foundation Model returned an invalid puzzle. Try again."
        }
    }
}
