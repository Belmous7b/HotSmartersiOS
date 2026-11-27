import Foundation

/// Lightweight download-speed probe used by the speed test. Mirrors Android `NetworkSpeed`.
enum NetworkSpeed {
    static func measureMbps(bytes: Int = 3_000_000) async -> Double? {
        guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=\(bytes)") else { return nil }
        let start = DispatchTime.now().uptimeNanoseconds
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let seconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000.0
            if seconds <= 0 { return nil }
            return (Double(data.count) * 8.0 / 1_000_000.0) / seconds
        } catch {
            return nil
        }
    }

    static func label(_ mbps: Double?) -> String {
        guard let mbps else { return "Failed" }
        switch mbps {
        case ..<5: return "Poor"
        case ..<15: return "Medium"
        case ..<40: return "Good"
        default: return "Excellent"
        }
    }
}
