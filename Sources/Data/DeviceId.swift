import Foundation
import CryptoKit
#if canImport(UIKit)
import UIKit
#endif

/// A stable, unique MAC + KEY for this device/install, derived (hashed) from a
/// stable per-install id so both are identical on every launch and match the
/// Android scheme against the activation panel.
///
/// Android used `ANDROID_ID`; on iOS we use `identifierForVendor`, persisting a
/// random fallback UUID once if it is nil.
enum DeviceId {

    static func mac() -> String { formatMac(hashHex(seed() + "|mac")) }

    /// A stable 6-digit code derived from the device id.
    static func key() -> String {
        let hex = String(hashHex(seed() + "|key").prefix(8))
        let n = (UInt64(hex, radix: 16) ?? 0) % 1_000_000
        let s = String(n)
        return String(repeating: "0", count: max(0, 6 - s.count)) + s
    }

    /// Backwards-compatible alias (returns the MAC).
    static func get() -> String { mac() }

    private static let fallbackKey = "hsu_identity_fallback"

    private static func seed() -> String {
        #if canImport(UIKit)
        if let idfv = UIDevice.current.identifierForVendor?.uuidString, !idfv.isEmpty {
            return idfv
        }
        #endif
        let d = UserDefaults.standard
        if let saved = d.string(forKey: fallbackKey), !saved.isEmpty { return saved }
        let fresh = UUID().uuidString
        d.set(fresh, forKey: fallbackKey)
        return fresh
    }

    private static func hashHex(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02X", $0) }.joined()
    }

    private static func formatMac(_ hex: String) -> String {
        let first12 = Array(hex.prefix(12))
        var pairs: [String] = []
        var i = 0
        while i < first12.count {
            pairs.append(String(first12[i]) + String(first12[i + 1]))
            i += 2
        }
        return pairs.joined(separator: ":")
    }
}
