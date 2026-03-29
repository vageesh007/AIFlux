import SwiftUI

struct GameView: View {
    @StateObject private var puzzleManager = PuzzleManager()
    @State private var showDebug = false
    @State private var tickerPulse = false
    @State private var isWaveActive = false
    @State private var waveStartDate = Date()
    @State private var lastPuzzleID: UUID?
    
    private var isInitialLoading: Bool {
        puzzleManager.currentPuzzle == nil && puzzleManager.isLoading
    }
    
    private var isEmptyState: Bool {
        puzzleManager.currentPuzzle == nil && !puzzleManager.isLoading
    }

    var body: some View {
        ZStack {
            if isInitialLoading {
                MetalLoaderView()
            } else if isEmptyState {
                emptyStateView
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.97, blue: 1.00),
                        Color(red: 0.98, green: 0.95, blue: 0.98),
                        Color(red: 0.96, green: 0.98, blue: 0.93)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                    VStack(spacing: 12) {
                        header
                        generationBanner
                        clueCard
                        board
                        typingTicker
                        controls
                        if showDebug {
                            debugPanel
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                .waterWaveEffect(isActive: isWaveActive, startDate: waveStartDate)

            }
        }
        .task {
            await puzzleManager.startGame()
        }
        .onChange(of: puzzleManager.roundResult) { _, newValue in
            guard let newValue else {
                return
            }
            switch newValue {
            case .correct:
                FeedbackManager.playSuccess()
                triggerWaveTransition()
            case .incorrect:
                FeedbackManager.playError()
            }
        }
        .onChange(of: puzzleManager.currentPuzzle?.id) { _, newValue in
            guard let newValue else {
                return
            }
            if lastPuzzleID == nil {
                lastPuzzleID = newValue
                isWaveActive = false
                return
            }

            if newValue != lastPuzzleID {
                lastPuzzleID = newValue
                withAnimation(.easeOut(duration: 0.22)) {
                    isWaveActive = false
                }
            }
        }
        .onChange(of: puzzleManager.assembledWord) { _, _ in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                tickerPulse.toggle()
            }
        }
        .onChange(of: puzzleManager.generationStatus) { _, newValue in
            if newValue.contains("failed") || newValue.contains("unavailable") {
                withAnimation(.easeOut(duration: 0.22)) {
                    isWaveActive = false
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        ZStack {
            MetalLoaderView()

            VStack(spacing: 12) {
                Text("Unable to load question")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color(red: 0.28, green: 0.31, blue: 0.42))

                Text(puzzleManager.generationStatus)
                    .font(.footnote)
                    .foregroundStyle(Color(red: 0.42, green: 0.47, blue: 0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button("Retry") {
                    Task { await puzzleManager.loadNextPuzzle() }
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Color(red: 0.35, green: 0.46, blue: 0.73), in: Capsule())
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OneWord")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.20, green: 0.24, blue: 0.36))

            HStack(spacing: 10) {
                statPill(title: "Puzzle", value: "#\(puzzleManager.puzzleNumber)")
                statPill(title: "Score", value: "\(puzzleManager.score)")
                statPill(title: "Combo", value: "x\(max(1, puzzleManager.combo))")
            }
        }
    }

    private var generationBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(puzzleManager.generationStatus.contains("OK") ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(puzzleManager.generationStatus)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.28, green: 0.31, blue: 0.42))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 1)
                )
        )
    }

    private var clueCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(puzzleManager.currentPuzzle?.category ?? "One Word Substitution")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(red: 0.37, green: 0.42, blue: 0.59))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(red: 0.87, green: 0.90, blue: 1.0), in: Capsule())

            Text("Find the one-word answer")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(red: 0.45, green: 0.48, blue: 0.63))

            ScrollView(showsIndicators: false) {
                Text(puzzleManager.currentPuzzle?.clue ?? "Generating clue...")
                    .font(.system(size: clueFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.21, green: 0.25, blue: 0.35))
                    .lineLimit(nil)
                    .minimumScaleFactor(0.65)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .id(puzzleManager.currentPuzzle?.id)
            }
            .frame(height: 96)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 180)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.92))
                .shadow(color: Color(red: 0.62, green: 0.70, blue: 0.90).opacity(0.25), radius: 14, x: 0, y: 8)
        )
    }

    private var board: some View {
        Group {
            if let puzzle = puzzleManager.currentPuzzle {
                LetterBoardView(
                    tiles: puzzle.letters,
                    selectedTileIDs: puzzleManager.selectedTileIDs,
                    roundResult: puzzleManager.roundResult,
                    onSelectTile: { tileID in
                        FeedbackManager.playSelection()
                        puzzleManager.selectLetter(tileID: tileID)
                    }
                )
            } else {
                VStack(spacing: 10) {
                    Text("Question unavailable")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color(red: 0.30, green: 0.34, blue: 0.50))
                    Button("Retry") {
                        Task { await puzzleManager.loadNextPuzzle() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.white, in: Capsule())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 20))
            }
        }
        .frame(height: 300)
    }

    private var typingTicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live Typing")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.47, green: 0.50, blue: 0.66))

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(red: 0.84, green: 0.88, blue: 0.98), lineWidth: 1.5)
                    )
                    .shadow(color: Color(red: 0.66, green: 0.72, blue: 0.88).opacity(0.20), radius: 10, y: 6)

                TimelineView(.animation) { timeline in
                    let blink = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
                    HStack(spacing: 4) {
                        Text(puzzleManager.assembledWord.isEmpty ? "TAP LETTERS..." : puzzleManager.assembledWord)
                            .font(.system(size: 34, weight: .black, design: .monospaced))
                            .tracking(3)
                            .foregroundStyle(
                                puzzleManager.assembledWord.isEmpty
                                    ? Color(red: 0.64, green: 0.67, blue: 0.76)
                                    : Color(red: 0.20, green: 0.24, blue: 0.34)
                            )
                            .id(puzzleManager.assembledWord)
                            .scaleEffect(tickerPulse ? 1.03 : 1)

                        Text(blink ? "▌" : " ")
                            .font(.system(size: 30, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(red: 0.38, green: 0.44, blue: 0.66))
                    }
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 78)
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    puzzleManager.useHint()
                    FeedbackManager.playSelection()
                } label: {
                    controlLabel(title: "Hint", icon: "lightbulb.max")
                }
                .disabled(puzzleManager.currentPuzzle == nil)

                Button {
                    puzzleManager.removeLastSelection()
                    FeedbackManager.playSelection()
                } label: {
                    controlLabel(title: "Back", icon: "delete.left")
                }
                .disabled(puzzleManager.currentPuzzle == nil || puzzleManager.assembledWord.isEmpty)
            }
            
            HStack(spacing: 12) {
                Button {
                    puzzleManager.shuffleLetters()
                } label: {
                    controlLabel(title: "Shuffle", icon: "shuffle")
                }
                .disabled(puzzleManager.isLoading || puzzleManager.currentPuzzle == nil)

                Button {
                    Task { await puzzleManager.loadNextPuzzle() }
                } label: {
                    controlLabel(title: "Next", icon: "arrow.right.circle")
                }
                .disabled(puzzleManager.isLoading)
            }

            Button(showDebug ? "Hide AI Debug" : "Show AI Debug") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDebug.toggle()
                }
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color(red: 0.42, green: 0.47, blue: 0.66))
        }
    }

    private var debugPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AI Debug")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(red: 0.30, green: 0.50, blue: 0.35))

            ForEach(puzzleManager.debugLines.indices, id: \.self) { index in
                Text(puzzleManager.debugLines[index])
                    .font(.caption2.monospaced())
                    .foregroundStyle(Color(red: 0.28, green: 0.31, blue: 0.42))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.83, green: 0.92, blue: 0.84), lineWidth: 1)
                )
        )
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color(red: 0.58, green: 0.60, blue: 0.72))
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color(red: 0.30, green: 0.34, blue: 0.50))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(width: 74)
        .background(Color.white.opacity(0.86), in: Capsule())
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }

    private func controlLabel(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color(red: 0.26, green: 0.30, blue: 0.44))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(Color(red: 0.85, green: 0.88, blue: 0.97), lineWidth: 1)
                )
        )
    }

    private func triggerWaveTransition() {
        waveStartDate = Date()
        isWaveActive = true
    }
    
    private var clueFontSize: CGFloat {
        let count = puzzleManager.currentPuzzle?.clue.count ?? 0
        switch count {
        case 0...55:
            return 24
        case 56...90:
            return 21
        case 91...130:
            return 18
        default:
            return 16
        }
    }
}

#Preview {
    GameView()
}
