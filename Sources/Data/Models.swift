import Foundation

// MARK: - Content models (mirror the Android data classes)

struct LiveChannel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let logo: String?
    let group: String?
    let url: String
    var tvgId: String? = nil
    var archive: Bool = false
}

enum VodType: String, Codable { case movie, series }

struct VodItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let poster: String?
    let group: String?
    /// direct play url; blank for Xtream series (needs episode lookup)
    let url: String
    let type: VodType
}

struct Episode: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let url: String
    var season: Int = 0
    var episodeNum: Int = 0
    var plot: String = ""
    var cover: String = ""
}

struct ParsedPlaylist {
    let live: [LiveChannel]
    let movies: [VodItem]
    let series: [VodItem]
    var tvgUrl: String? = nil
}

struct SportEvent: Identifiable, Hashable {
    var id: String { name + time }
    let name: String
    let league: String
    let time: String
    let thumb: String?
    var startMs: Int64 = 0
}

struct EpgProgramme: Hashable {
    let title: String
    let desc: String
    let startMs: Int64
    let stopMs: Int64
}

struct Category: Identifiable, Codable, Hashable {
    let id: String
    let name: String
}

let UNCATEGORIZED = "Uncategorized"

enum MediaKind: String, Codable { case live, movie, series }

struct TmdbInfo {
    let poster: String?
    let backdrop: String?
    let overview: String
    let rating: Double
    let year: String
    let genres: [String]
    let trailerKey: String?
}

struct EpgEntry: Hashable {
    let title: String
    let start: String
    let end: String
    let description: String
    let nowPlaying: Bool
}
