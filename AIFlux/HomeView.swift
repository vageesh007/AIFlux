import SwiftUI

struct HomeView: View {
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.09),
                    Color(red: 0.06, green: 0.09, blue: 0.16),
                    Color(red: 0.02, green: 0.03, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                Text("WordFlux")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .cyan.opacity(0.45), radius: 18)

                Text("One-word substitution puzzles powered by on-device AI")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer()

                Button {
                    isPlaying = true
                } label: {
                    Text("Play")
                        .font(.title3.bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.cyan)
                                .shadow(color: .cyan.opacity(0.55), radius: 16)
                        )
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 44)
            }
        }
        .fullScreenCover(isPresented: $isPlaying) {
            GameView()
        }
    }
}

#Preview {
    HomeView()
}
