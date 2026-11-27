# Hot Smarters — iOS

A native **iOS (Swift / SwiftUI)** 1:1 clone of the Android IPTV app **Hot Smarters**
(`HotSmartersUltra`). It streams **Live TV, Movies (VOD) and Series** from an Xtream
Codes login or an M3U URL, enriched with **TMDB** metadata, gated by the activation
panel at `https://hotsmarters.app`, keyed by a stable device MAC + 6‑digit key.

- **Bundle id:** `com.hotsmarters.player`
- **Display name:** Hot Smarters
- **Platforms:** iPhone + iPad (universal), iOS 16+
- **UI:** SwiftUI, `AVKit`/`AVPlayer` for video, `CoreImage` for QR codes, `AsyncImage`
  for artwork. No third‑party SDKs.

## Build & run

1. Open **`HotSmartersiOS.xcodeproj`** in **Xcode 16 or newer** (the project uses the
   modern *synchronized folder* format, so every file under `Sources/` is compiled
   automatically — just add new files to that folder, no project edits needed).
2. Select the **HotSmartersiOS** scheme and an iPhone/iPad simulator (or a device).
3. For a device build, set your Team under *Signing & Capabilities* (signing is
   Automatic; the bundle id is `com.hotsmarters.player`).
4. **Run** (⌘R).

> This project was authored on Windows and must be **built on a Mac with Xcode** —
> iOS apps cannot compile on Windows. All source, assets and settings are ready to go.

## Project layout (mirrors the Android packages)

```
HotSmartersiOS/
├─ HotSmartersiOS.xcodeproj/
├─ Info.plist                      # ATS arbitrary loads, orientations, display name
├─ README.md
└─ Sources/
   ├─ App/            HotSmartersApp.swift        # @main, theming, RTL, language reload
   ├─ Navigation/     Router.swift, AppNavigation.swift
   ├─ Data/           models, DeviceId, Http, XtreamClient, M3uParser, Activation,
   │                  Prefs, stores, ContentRepository/ContentCache, TmdbClient,
   │                  OpenSubtitlesClient, SportsClient, Epg, NetworkSpeed, I18n,
   │                  Translations, …
   ├─ UI/Theme/       Theme.swift                 # crimson #E50914 on near‑black #080808
   ├─ UI/Components/   RemoteImage, PosterCard, SearchField, QrCode, AppDialog,
   │                   Support, PinDialog, FavoriteDialog, PlayerController, VideoPlayerView
   ├─ UI/             ActivationGate.swift
   ├─ UI/Screens/     Welcome, AddPlaylist, Playlists, Dashboard, Home, Live, Vod,
   │                   MovieDetail, SeriesDetail, Player, Search, Favorites,
   │                   WatchLater, Sport, SpeedTest, Settings, Account
   └─ Assets.xcassets/  AppIcon, logo, logo_icon, AccentColor
```

## Notes on the iOS port

- **Video:** `AVPlayer` via `AVPlayerViewController` gives native controls, scrubbing
  and embedded audio/subtitle track selection. Streams carry the VLC
  `User-Agent` (many IPTV servers reject unknown clients). Resume position, silent
  auto‑reconnect, keep‑awake and auto‑play‑next are handled in `PlayerController`.
- **External subtitles:** OpenSubtitles fetch + on‑screen overlay with ±0.5s time‑shift.
- **Activation / panel:** identical JSON contract (`/api/activate`, `/api/app-playlists`,
  `/api/customer/delete-playlist`). The device MAC/key hash scheme matches Android, using
  `identifierForVendor` (with a persisted random fallback) as the seed.
- **Languages:** 14 languages, instant switch, Arabic RTL; the full `Translations` table
  is ported from Android with English fallback for anything missing.
- **Cleartext HTTP** is enabled via `NSAppTransportSecurity → NSAllowsArbitraryLoads`.
- The in‑app updater opens the panel's download / App Store URL (no sideloading on iOS).
- The app icon was generated at 1024×1024 (opaque) from the Android launcher mark; swap
  in your own artwork before shipping if desired.
