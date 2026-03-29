import SwiftUI

struct MetalLoaderView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.80, green: 0.89, blue: 1.00),
                            Color(red: 0.93, green: 0.83, blue: 0.99),
                            Color(red: 0.86, green: 0.96, blue: 0.90)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .visualEffect { view, proxy in
                    view.colorEffect(
                        Shader(
                            function: .init(library: .default, name: "loaderGlow"),
                            arguments: [
                                .float2(Float(proxy.size.width), Float(proxy.size.height)),
                                .float(Float(t))
                            ]
                        )
                    )
                }
                .overlay {
                    VStack(spacing: 12) {
                        Text("OneWord")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 0.24, green: 0.28, blue: 0.40))
                        Text("Generating question...")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color(red: 0.33, green: 0.37, blue: 0.53))
                    }
                }
                .ignoresSafeArea()
        }
    }
}
