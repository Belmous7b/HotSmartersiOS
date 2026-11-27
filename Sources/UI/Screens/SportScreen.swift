import SwiftUI

/// Sports hub via TheSportsDB; events list with league/time/thumb per day.
/// Mirrors Android `SportScreen` (screen kept; tile hidden on the dashboard).
struct SportScreen: View {
    let onBack: () -> Void

    private struct Day: Identifiable { var id: String { date }; let label: String; let date: String }
    @State private var selected = ""
    @State private var events: [SportEvent]?

    private let days: [Day] = {
        let dateFmt = DateFormatter(); dateFmt.locale = Locale(identifier: "en_US_POSIX"); dateFmt.dateFormat = "yyyy-MM-dd"
        let labelFmt = DateFormatter(); labelFmt.dateFormat = "EEE dd MMM"
        return (0..<7).map { offset in
            let d = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
            let label = offset == 0 ? "Today" : (offset == 1 ? "Tomorrow" : labelFmt.string(from: d))
            return Day(label: label, date: dateFmt.string(from: d))
        }
    }()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "arrow.left").foregroundStyle(.white) }
                Text("Sport").font(.headline).foregroundStyle(.white)
                Spacer()
            }
            .padding()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(days) { d in dayChip(d.label, selected == d.date) { selected = d.date } }
                }
                .padding(12)
            }

            Group {
                if events == nil {
                    ProgressView().tint(.hotRed).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if (events ?? []).isEmpty {
                    Text("No football events for this day.").foregroundStyle(Color.textSecondary).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView { LazyVStack(spacing: 0) { ForEach(events ?? []) { eventRow($0) } } }
                }
            }
        }
        .background(Color.darkBg)
        .task { if selected.isEmpty { selected = days.first?.date ?? "" } }
        .onChange(of: selected) { new in
            events = nil
            Task { events = await SportsClient.eventsOn(date: new) }
        }
    }

    private func dayChip(_ label: String, _ sel: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).fontWeight(sel ? .bold : .regular).foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(sel ? Color.hotRed : Color.darkSurface).clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func eventRow(_ event: SportEvent) -> some View {
        HStack(spacing: 12) {
            RemoteImage(url: event.thumb, contentMode: .fill) {
                ZStack { Color.darkSurface2; Image(systemName: "soccerball").foregroundStyle(Color.textSecondary) }
            }
            .frame(width: 56, height: 56).clipped().clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name).fontWeight(.bold).foregroundStyle(.white).lineLimit(1)
                Text(event.league).font(.caption).foregroundStyle(Color.textSecondary).lineLimit(1)
            }
            Spacer()
            Text(event.time).fontWeight(.bold).foregroundStyle(Color.hotRed)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}
