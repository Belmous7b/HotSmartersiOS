import SwiftUI

/// Network download speed test with a rating + advice. Mirrors Android `SpeedTestScreen`.
struct SpeedTestScreen: View {
    let onBack: () -> Void

    private struct Rating { let label: String; let advice: String; let color: Color }
    @State private var running = false
    @State private var mbps: Double?
    @State private var done = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "arrow.left").foregroundStyle(.white) }
                Text("Internet Speed Test").font(.headline).foregroundStyle(.white)
                Spacer()
            }
            .padding()

            VStack(spacing: 0) {
                Spacer()
                if running {
                    ProgressView().tint(.hotRed)
                    Text("Testing your connection…").foregroundStyle(.white).padding(.top, 16)
                } else if done {
                    let r = rate(mbps)
                    Text(mbps == nil ? "—" : String(format: "%.1f", mbps!) + " Mbps")
                        .font(.system(size: 40, weight: .black)).foregroundStyle(r.color)
                    Text(r.label).font(.title2.bold()).foregroundStyle(r.color).padding(.top, 4)
                    Text(r.advice).multilineTextAlignment(.center).foregroundStyle(Color.textSecondary).padding(.top, 10)
                } else {
                    Text("Check your connection before streaming.").foregroundStyle(Color.textSecondary)
                }
                Spacer().frame(height: 28)
                Button {
                    Task {
                        running = true; done = false
                        mbps = await NetworkSpeed.measureMbps(bytes: 10_000_000)
                        running = false; done = true
                    }
                } label: {
                    Text(done ? "Test again" : "Start test").fontWeight(.bold).foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 12).background(Color.hotRed).clipShape(Capsule())
                }
                .disabled(running)
                Spacer()
            }
            .padding(24)
        }
        .background(Color.darkBg)
    }

    private func rate(_ mbps: Double?) -> Rating {
        guard let mbps else { return Rating(label: "Failed", advice: "Couldn't reach the test server. Check your connection.", color: Color(hex: 0xFF3D3D)) }
        switch mbps {
        case ..<5: return Rating(label: "Poor", advice: "SD only — expect buffering on HD channels.", color: Color(hex: 0xFF3D3D))
        case ..<15: return Rating(label: "Medium", advice: "Fine for HD. 4K streams may buffer.", color: Color(hex: 0xFF7A00))
        case ..<40: return Rating(label: "Good", advice: "Full HD is smooth; most 4K will play.", color: Color(hex: 0x4CAF50))
        default: return Rating(label: "Excellent", advice: "4K-ready. You're all set.", color: Color(hex: 0x4CAF50))
        }
    }
}
