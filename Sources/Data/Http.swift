import Foundation

/// Networking layer mirroring the Android `Http` object.
/// - Sends the widely-accepted VLC User-Agent (many IPTV servers reject unknown clients).
/// - A long-timeout client for content, a short one (~8s) for panel/control calls so
///   launch never hangs.
/// - Cleartext HTTP is allowed via `NSAppTransportSecurity` in Info.plist.
enum Http {
    static let userAgent = "VLC/3.0.20 LibVLC/3.0.20"

    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 90
        cfg.waitsForConnectivity = true
        cfg.httpAdditionalHeaders = ["User-Agent": userAgent]
        return URLSession(configuration: cfg)
    }()

    private static let shortSession: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 8
        cfg.timeoutIntervalForResource = 12
        cfg.httpAdditionalHeaders = ["User-Agent": userAgent]
        return URLSession(configuration: cfg)
    }()

    struct Resp { let ok: Bool; let body: String? }

    /// GET a URL's text (2 attempts, 800 ms backoff). Returns nil on any failure.
    static func getString(_ urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }
        for attempt in 0..<2 {
            var req = URLRequest(url: url)
            req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            req.setValue("*/*", forHTTPHeaderField: "Accept")
            do {
                let (data, resp) = try await session.data(for: req)
                if let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                    return String(data: data, encoding: .utf8)
                }
            } catch {
                // fall through to retry
            }
            if attempt == 0 { try? await Task.sleep(nanoseconds: 800_000_000) }
        }
        return nil
    }

    /// POST a JSON body and return the response text, or nil on any failure.
    @discardableResult
    static func postJson(_ urlString: String, json: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = json.data(using: .utf8)
        do {
            let (data, resp) = try await shortSession.data(for: req)
            if let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                return String(data: data, encoding: .utf8)
            }
        } catch {}
        return nil
    }

    /// Like postJson, but reports (ok, body) on any HTTP response, or nil when the
    /// request couldn't be sent. Lets callers read an {error} code.
    static func postJsonResult(_ urlString: String, json: String) async -> Resp? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = json.data(using: .utf8)
        do {
            let (data, resp) = try await shortSession.data(for: req)
            let ok = (resp as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
            return Resp(ok: ok, body: String(data: data, encoding: .utf8))
        } catch {
            return nil
        }
    }

    /// Download a URL into a destination file. Returns true on success.
    static func download(_ urlString: String, to dest: URL) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        do {
            let (tmp, resp) = try await session.download(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return false }
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tmp, to: dest)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Small JSON helpers used across the data layer.

extension String {
    /// URL-encode a query component the way Android's URLEncoder does for user/pass.
    var urlEncoded: String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_.*")
        return addingPercentEncoding(withAllowedCharacters: allowed)?
            .replacingOccurrences(of: "%20", with: "+") ?? self
    }
}
