import SwiftUI

struct WaterWaveEffect: ViewModifier {
    let isActive: Bool
    let startDate: Date

    @ViewBuilder
    func body(content: Content) -> some View {
        if isActive {
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startDate)

                content.visualEffect { view, proxy in
                    view.distortionEffect(
                        Shader(
                            function: .init(library: .default, name: "waterRipple"),
                            arguments: [
                                .float2(Float(proxy.size.width), Float(proxy.size.height)),
                                .float(Float(elapsed)),
                                .float(1)
                            ]
                        ),
                        maxSampleOffset: CGSize(width: 20, height: 20)
                    )
                }
            }
        } else {
            content
        }
    }
}

extension View {
    func waterWaveEffect(isActive: Bool, startDate: Date) -> some View {
        modifier(WaterWaveEffect(isActive: isActive, startDate: startDate))
    }
}
