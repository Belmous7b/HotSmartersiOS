import SwiftUI

private enum SortMode: String, CaseIterable {
    case recent = "Recently added"
    case nameAsc = "A – Z"
    case nameDesc = "Z – A"
    case yearDesc = "Year (newest)"
}

/// The VOD grid used within Home for Movies and Series. Category cards → poster
/// grid, with search + sort. Mirrors Android `VodScreen`.
struct VodScreen: View {
    let items: [VodItem]
    let categories: [Category]
    let unitLabel: String  // "movies" | "series"
    let onClick: (VodItem) -> Void

    @State private var query = ""
    @State private var openCat: Category?
    @State private var unlocked: Set<String> = []
    @State private var pendingCat: Category?
    @State private var sort: SortMode = .recent
    @State private var searchOpen = false

    private var unit: String { tr(unitLabel.prefix(1).uppercased() + String(unitLabel.dropFirst())) }
    private let allId = "__all__"

    private var counts: [String: Int] {
        Dictionary(items.map { (($0.group?.nonBlank ?? UNCATEGORIZED), 1) }, uniquingKeysWith: +)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { searchOpen.toggle(); if !searchOpen { query = "" } } label: {
                    Image(systemName: "magnifyingglass").foregroundStyle(.white)
                }
                Text(searchOpen ? "\(tr("Search")) \(unit)" : unit).font(.headline).foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            if searchOpen {
                SearchField(query: $query, hint: "\(tr("Search")) \(unit)").padding(.horizontal, 12).padding(.vertical, 4)
            }

            if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                let results = sortItems(items.filter { $0.name.range(of: query, options: .caseInsensitive) != nil })
                header("\(tr("Results")) (\(results.count))", back: nil)
                posterGrid(results)
            } else if let cat = openCat {
                let base = cat.id == allId ? items : items.filter { ($0.group?.nonBlank ?? UNCATEGORIZED) == cat.id }
                let list = sortItems(base)
                header("\(cat.name) (\(list.count))", back: { openCat = nil })
                posterGrid(list)
            } else {
                categoryGrid
            }
        }
        .background(Color.darkBg)
        .appDialog(item: $pendingCat) { cat in
            PinDialog(onDismiss: { pendingCat = nil }, onSuccess: { unlocked.insert(cat.id); openCat = cat; pendingCat = nil })
        }
    }

    private func header(_ title: String, back: (() -> Void)?) -> some View {
        HStack {
            if let back { Button(action: back) { Image(systemName: "arrow.left").foregroundStyle(.white) } }
            Text(title).fontWeight(.bold).foregroundStyle(.white).padding(.leading, 4)
            Spacer()
            Menu {
                ForEach(SortMode.allCases, id: \.self) { m in Button(m.rawValue) { sort = m } }
            } label: {
                HStack(spacing: 4) { Image(systemName: "arrow.up.arrow.down"); Text(sort.rawValue).font(.caption) }
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
    }

    private func posterGrid(_ list: [VodItem]) -> some View {
        Group {
            if list.isEmpty {
                EmptyStateView(tr("Nothing here."))
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 10)], spacing: 10) {
                        ForEach(list) { item in PosterCard(item: item) { onClick(item) } }
                    }
                    .padding(12)
                }
            }
        }
    }

    private var categoryGrid: some View {
        let shown = categories.filter { (counts[$0.id] ?? 0) > 0 }
        return ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                categoryCard("\(tr("All")) \(unit)", items.count, index: 0, catId: allId) {
                    openCat = Category(id: allId, name: "\(tr("All")) \(unit)")
                }
                ForEach(Array(shown.enumerated()), id: \.element.id) { i, cat in
                    categoryCard(cat.name, counts[cat.id] ?? 0, index: i + 1, catId: cat.id) { openTapped(cat) }
                }
            }
            .padding(12)
        }
    }

    private func categoryCard(_ name: String, _ count: Int, index: Int, catId: String, action: @escaping () -> Void) -> some View {
        let accent: Color = index % 2 == 0 ? .hotRed : .hotOrange
        let posters = posterUrls(for: catId)
        let fallbackIcon = unitLabel == "series" ? "rectangle.stack.fill" : "film.fill"
        return Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        ZStack {
                            Color.darkBg
                            if i < posters.count {
                                RemoteImage(url: posters[i], contentMode: .fill)
                            } else {
                                Image(systemName: fallbackIcon)
                                    .font(.title3)
                                    .foregroundStyle(Color.textSecondary.opacity(0.4))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
                Text(name).font(.subheadline.bold()).foregroundStyle(.white).lineLimit(1)
                Text("\(count) \(unit)").font(.caption.bold()).foregroundStyle(accent)
            }
            .padding(8)
            .background(LinearGradient.brandCard)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// First few distinct poster URLs in a category, for the card's preview collage.
    private func posterUrls(for catId: String, limit: Int = 3) -> [String] {
        let pool = catId == allId ? items : items.filter { ($0.group?.nonBlank ?? UNCATEGORIZED) == catId }
        var urls: [String] = []
        for it in pool {
            guard let p = it.poster?.nonBlank else { continue }
            if !urls.contains(p) {
                urls.append(p)
                if urls.count >= limit { break }
            }
        }
        return urls
    }

    private func openTapped(_ cat: Category) {
        if isLockedCategory(cat.name) && !unlocked.contains(cat.id) { pendingCat = cat } else { openCat = cat }
    }

    private func sortItems(_ list: [VodItem]) -> [VodItem] {
        switch sort {
        case .recent: return list
        case .nameAsc: return list.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDesc: return list.sorted { $0.name.lowercased() > $1.name.lowercased() }
        case .yearDesc: return list.sorted { parseYear($0.name) > parseYear($1.name) }
        }
    }

    private func parseYear(_ name: String) -> Int {
        if let r = name.range(of: "(19|20)\\d{2}", options: .regularExpression) { return Int(name[r]) ?? 0 }
        return 0
    }
}
