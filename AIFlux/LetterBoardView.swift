import SwiftUI

struct LetterBoardView: View {
    let tiles: [LetterTile]
    let selectedTileIDs: [UUID]
    let roundResult: RoundResult?
    let onSelectTile: (UUID) -> Void

    @State private var shakeOffset: CGFloat = 0

    private let palette: [Color] = [
        Color(red: 0.72, green: 0.87, blue: 0.99),
        Color(red: 0.89, green: 0.81, blue: 0.97),
        Color(red: 0.98, green: 0.83, blue: 0.73),
        Color(red: 0.80, green: 0.95, blue: 0.83),
        Color(red: 0.98, green: 0.91, blue: 0.71),
        Color(red: 0.84, green: 0.90, blue: 0.98)
    ]

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 64), spacing: 10)]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color(red: 0.86, green: 0.90, blue: 0.98), lineWidth: 1.4)
                )
                .shadow(color: Color(red: 0.60, green: 0.67, blue: 0.86).opacity(0.20), radius: 14, y: 8)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(tiles) { tile in
                    tileButton(tile)
                }
            }
            .padding(14)
            .offset(x: shakeOffset)
        }
        .onChange(of: roundResult) { _, newValue in
            guard newValue == .incorrect else {
                return
            }
            withAnimation(.easeInOut(duration: 0.06)) { shakeOffset = -8 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(.easeInOut(duration: 0.06)) { shakeOffset = 8 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.06)) { shakeOffset = 0 }
            }
        }
    }

    @ViewBuilder
    private func tileButton(_ tile: LetterTile) -> some View {
        let isSelected = selectedTileIDs.contains(tile.id)
        let tileColor = palette[tile.index % palette.count]

        Button {
            guard !isSelected else {
                return
            }
            onSelectTile(tile.id)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(red: 0.35, green: 0.45, blue: 0.78) : tileColor)

                Text(tile.value)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(isSelected ? .white : Color(red: 0.23, green: 0.27, blue: 0.38))
            }
            .frame(height: 62)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.black.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color(red: 0.35, green: 0.45, blue: 0.78).opacity(0.35) : Color.black.opacity(0.08), radius: isSelected ? 10 : 3, y: isSelected ? 4 : 2)
            .scaleEffect(isSelected ? 0.88 : 1)
            .rotationEffect(.degrees(isSelected ? -2 : 0))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.22, dampingFraction: 0.70), value: isSelected)
    }
}
