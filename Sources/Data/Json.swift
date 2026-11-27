import Foundation

/// Tiny helpers over Foundation JSON so the client code reads like the Android
/// `org.json` calls (optString / optInt / optJSONArray …).
enum JSON {
    static func object(_ s: String?) -> [String: Any]? {
        guard let s, let d = s.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: d)) as? [String: Any]
    }
    static func array(_ s: String?) -> [Any]? {
        guard let s, let d = s.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: d)) as? [Any]
    }
    static func string(_ v: Any?) -> String {
        if let s = v as? String { return s }
        if let n = v as? NSNumber { return n.stringValue }
        return ""
    }
    static func stringify(_ obj: Any) -> String {
        guard let d = try? JSONSerialization.data(withJSONObject: obj) else { return "{}" }
        return String(data: d, encoding: .utf8) ?? "{}"
    }
}

extension Dictionary where Key == String, Value == Any {
    func optString(_ key: String) -> String {
        if self[key] is NSNull { return "" }
        return JSON.string(self[key])
    }
    func optInt(_ key: String, _ def: Int = 0) -> Int {
        if let n = self[key] as? NSNumber { return n.intValue }
        if let s = self[key] as? String { return Int(s) ?? def }
        return def
    }
    func optDouble(_ key: String, _ def: Double = 0) -> Double {
        if let n = self[key] as? NSNumber { return n.doubleValue }
        if let s = self[key] as? String { return Double(s) ?? def }
        return def
    }
    func optLong(_ key: String, _ def: Int64 = 0) -> Int64 {
        if let n = self[key] as? NSNumber { return n.int64Value }
        if let s = self[key] as? String { return Int64(s) ?? def }
        return def
    }
    func optBool(_ key: String, _ def: Bool = false) -> Bool {
        if let n = self[key] as? NSNumber { return n.boolValue }
        if let b = self[key] as? Bool { return b }
        return def
    }
    func optObject(_ key: String) -> [String: Any]? { self[key] as? [String: Any] }
    func optArray(_ key: String) -> [Any]? { self[key] as? [Any] }
    func isNull(_ key: String) -> Bool { self[key] == nil || self[key] is NSNull }
}

extension String {
    var nonBlank: String? { isEmpty ? nil : self }
    func ifBlank(_ fallback: String) -> String { isEmpty ? fallback : self }
}
