import SwiftUI

struct DynamicBackgroundView: View {
    let colors: [Color]
    @State private var animate = false

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated overlay circles for dynamic effect
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        colors[index % colors.count]
                            .opacity(0.3)
                    )
                    .blur(radius: 60)
                    .scaleEffect(animate ? 1.2 : 0.8)
                    .offset(
                        x: animate ? CGFloat.random(in: -50...50) : CGFloat.random(in: -30...30),
                        y: animate ? CGFloat.random(in: -50...50) : CGFloat.random(in: -30...30)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...5))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.3),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    DynamicBackgroundView(colors: [.blue, .purple, .pink])
}
