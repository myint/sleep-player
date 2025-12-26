# CLAUDE.md - Project Context for AI Assistants

This file contains context and implementation details for AI assistants working on this project in future sessions.

## Project Overview

**Sleep Timer Media Player** is a native macOS application that plays audio and video files with an integrated sleep timer that fades out and pauses playback after a configurable duration.

**Purpose**: Allow users to fall asleep while listening to audio/watching video, with automatic fade-out and pause (resumable).

**Current Status**: ✅ **Fully Functional** - Core features complete and tested. Builds successfully with Xcode 13.4+.

## Quick Context

- **Technology**: Swift 5.9+ with SwiftUI
- **Platform**: macOS 12.0 (Monterey) or later
- **Architecture**: MVVM pattern with Observable state objects
- **Build System**: Xcode project (not Swift Package Manager)
- **Version Control**: Git (2 commits as of initial implementation)

## Project Structure

```
sleep-player/
├── SleepPlayer.xcodeproj/           # Xcode project configuration
├── SleepPlayer/                     # Source code directory
│   ├── App/
│   │   └── SleepPlayerApp.swift    # @main entry point, wires up state objects
│   ├── Models/
│   │   ├── MediaPlayerState.swift  # Observable state for media playback
│   │   └── SleepTimerState.swift   # Observable state for timer
│   ├── Services/
│   │   ├── MediaPlayerService.swift    # AVPlayer wrapper, audio/video detection
│   │   ├── SleepTimerService.swift     # Timer countdown + volume fade logic
│   │   └── MediaKeyHandler.swift       # MPRemoteCommandCenter integration
│   ├── Views/
│   │   ├── ContentView.swift           # Main container, conditional video display
│   │   ├── VideoPlayerView.swift       # SwiftUI VideoPlayer wrapper
│   │   ├── PlayerControlsView.swift    # Playback UI + file picker
│   │   └── SleepTimerView.swift        # Timer UI with presets
│   ├── Assets.xcassets/            # App icon (currently default)
│   ├── Info.plist                  # App metadata
│   └── SleepPlayer.entitlements    # Sandboxing permissions
├── Makefile                        # Build automation (build, dmg, install)
├── README.md                       # User-facing documentation
├── CLAUDE.md                       # This file (AI context)
└── .gitignore                      # Xcode-specific ignores

```

## Architecture & Design Decisions

### MVVM Pattern
- **Models**: `MediaPlayerState`, `SleepTimerState` - Observable objects published to views
- **Views**: SwiftUI views that observe state changes
- **Services**: Business logic classes that manipulate state

### Key Design Choices

1. **AVPlayer over AVAudioPlayer**
   - Chosen to support both audio AND video with single API
   - More complex but unified approach

2. **No Persistence**
   - Deliberate decision to keep app simple
   - Fresh start every launch
   - Could be added via UserDefaults or AppStorage

3. **Fade-out Implementation**
   - 80 steps at 0.1s intervals = 8 second fade
   - Volume interpolation from current → 0
   - Pauses (not stops) so playback is resumable
   - Volume reset to 1.0 after pause for next playback

4. **State Wiring**
   - `SleepTimerService` needs reference to `MediaPlayerState` to control volume/pause
   - Connected in `SleepPlayerApp.onAppear`
   - `MediaKeyHandler` similarly wired to `MediaPlayerState`

5. **Media Type Detection**
   - Async check for video tracks using `AVAsset.loadTracks(withMediaType: .video)`
   - UI conditionally shows VideoPlayer only when `mediaType == .video`

6. **Media Control Integration**
   - Info.plist declares app as `public.app-category.music` for proper media player categorization
   - Now Playing Info set aggressively (on load, play, pause) to claim media control priority
   - `playbackState` explicitly set to `.playing` or `.paused` for macOS media key routing

## Implementation Details

### MediaPlayerService (SleepPlayer/Services/MediaPlayerService.swift)

**Key Methods**:
- `loadMedia(url:)` - Creates AVPlayer, detects media type, adds observers
- `play()`, `pause()`, `stop()` - Playback control
- `setVolume(_:)` - Used by fade-out logic
- `detectMediaType(asset:)` - Async check for video tracks

**Important Notes**:
- Uses `AVPlayerItem` observer for status tracking
- Adds periodic time observer (0.5s interval) for progress updates
- Cleanup in `deinit` to remove observers

### SleepTimerService (SleepPlayer/Services/SleepTimerService.swift)

**Key Methods**:
- `start(duration:)` - Starts countdown timer
- `cancel()` - Stops timer and fade
- `timerExpired()` - Triggers fade-out
- `startFadeOut()` - 80-step volume reduction

**Important Notes**:
- Uses Foundation `Timer` (not Combine)
- Needs reference to `MediaPlayerState` set via `setMediaPlayerState(_:)`
- Resets volume to 1.0 after fade completes (0.5s delay)

### MediaKeyHandler (SleepPlayer/Services/MediaKeyHandler.swift)

**Key Methods**:
- `setupRemoteCommandCenter()` - Registers play/pause/toggle handlers (on main thread)
- `updateNowPlayingInfo(...)` - Sets MPNowPlayingInfoCenter metadata and playback state

**Important Notes**:
- Uses `MPRemoteCommandCenter.shared()` for media key handling
- Handlers return `.success` or `.commandFailed`
- Needs reference to `MediaPlayerState` for play/pause actions
- **Critical**: Sets `MPNowPlayingInfoCenter.default().playbackState` to claim media control priority
- Updates Now Playing Info on main thread for thread safety
- Called from `MediaPlayerState.play()`, `pause()`, and `loadMedia()` to aggressively claim control

### UI Components

**ContentView**:
- Conditionally displays `VideoPlayerView` when `mediaType == .video`
- Shows audio placeholder (music note icon) for audio files
- Integrates `PlayerControlsView` and `SleepTimerView`

**PlayerControlsView**:
- File picker using `NSOpenPanel` with UTType filtering
- Play/pause button (spacebar shortcut)
- Stop button
- Volume slider
- Progress scrubber (seek functionality)
- Time displays (current/duration)

**SleepTimerView**:
- Preset buttons (15, 30, 45, 60 min)
- Start/Cancel buttons
- Countdown display (MM:SS format)
- Connects `SleepTimerService` to `MediaPlayerState` on start

**VideoPlayerView**:
- SwiftUI `VideoPlayer` with `.disabled(true)` to prevent default controls
- Only displayed when `mediaType == .video`

## Known Issues & Limitations

### Current Limitations
1. **No playlist support** - Only single file playback
2. **No persistence** - Settings/state not saved between launches
3. **No custom timer duration** - Only preset buttons available
4. **macOS 12.0+ only** - Originally targeted 12.0 for SwiftUI features

### Compatibility Fixes Applied
- Removed `.windowResizability(.contentSize)` - Only available in macOS 13+
- Using basic `WindowGroup` instead

### Potential Issues
- **Video aspect ratio** relies on VideoPlayer's automatic handling
- **No error handling** for invalid files (will fail silently or crash)
- **Media control priority** - macOS prioritizes the most recently active media player; if another app is playing, pause it first

## Common Tasks for Future Sessions

### Adding Persistence
1. Use `@AppStorage` in `MediaPlayerState` for volume, last file URL
2. Use `@AppStorage` in `SleepTimerState` for default timer duration
3. Store playback position using `UserDefaults`

Example:
```swift
@AppStorage("lastFileURL") private var lastFileURLString: String = ""
@AppStorage("defaultTimerDuration") private var timerDuration: TimeInterval = 1800
```

### Adding Playlist Support
1. Add `PlaylistState` model with array of URLs
2. Add next/previous buttons to `PlayerControlsView`
3. Modify `MediaPlayerService` to handle playlist progression
4. Add UI for playlist management (add/remove/reorder)

### Improving Error Handling
1. Add error states to `MediaPlayerState`
2. Use `do-catch` in `MediaPlayerService.loadMedia`
3. Display alerts in UI when file fails to load
4. Validate file types before loading

### Adding Keyboard Shortcuts
1. Use `.keyboardShortcut()` modifier on buttons
2. Add menu bar with keyboard shortcut hints
3. Register global hotkeys (requires accessibility permissions)

### Testing Checklist
- [x] Load MP3 file - verify playback
- [x] Load MP4 file - verify video displays
- [x] Set 1-minute timer - verify fade + pause works
- [x] Press AirPod button - verify play/pause works (fully functional)
- [ ] Seek through media - verify scrubber works
- [ ] Change file while playing - verify cleanup works
- [ ] Cancel timer mid-countdown - verify timer stops

## Build & Development

### Building with Makefile (Recommended)

A comprehensive Makefile is provided for development and distribution:

```bash
# Show all available commands
make help

# Build (Release configuration)
make build

# Build and run
make run

# Build debug version
make debug

# Clean all build artifacts
make clean

# Create distributable DMG
make dmg

# Create DMG with custom version
make dmg VERSION=1.2.0

# Install to /Applications
make install
```

**Makefile Configuration**:
- **Build directory**: `build/DerivedData/`
- **Output path**: `build/DerivedData/Build/Products/Release/SleepPlayer.app`
- **DMG output**: `SleepPlayer.dmg` (in project root)
- **Default configuration**: Release
- **Default version**: 1.0.0

**DMG Creation**:
- The `make dmg` target creates a compressed disk image (UDZO format)
- Includes symbolic link to /Applications for drag-and-drop installation
- Uses zlib compression level 9 for smallest file size
- Volume name: "Sleep Timer Media Player"

### Manual Building (without Makefile)

```bash
# Command line build
xcodebuild -project SleepPlayer.xcodeproj -scheme SleepPlayer -configuration Debug build

# Or open in Xcode
open SleepPlayer.xcodeproj
# Then press ⌘R
```

### Running
```bash
# Run built app (with Makefile)
make run

# Or manually
open build/DerivedData/Build/Products/Release/SleepPlayer.app
```

### Common Xcode Issues

**"Build input file cannot be found"**
- Check that source files are in correct locations
- Verify file references in project.pbxproj

**Swift version errors**
- Ensure deployment target is macOS 12.0
- Check Swift version in build settings (should be 5.0+)

**Signing errors**
- Use "Sign to Run Locally" in project settings
- Or set up development team in Signing & Capabilities

## Code Patterns

### Adding a New View
1. Create Swift file in `Views/` directory
2. Define SwiftUI `View` struct
3. Add `@EnvironmentObject` for needed state
4. Import in parent view and use
5. Add to Xcode project if not auto-added

### Adding a New Service
1. Create Swift file in `Services/` directory
2. Define class (not struct, need reference semantics)
3. Add weak reference to state object to avoid retain cycles
4. Wire up in `SleepPlayerApp.onAppear` if needed

### Observable State Pattern
```swift
class MyState: ObservableObject {
    @Published var property: Type = defaultValue

    func updateProperty() {
        property = newValue  // Automatically publishes change
    }
}
```

## Git Workflow

### Commits So Far
1. Initial implementation (all source files)
2. Xcode project + directory structure fix

### Recommended Commit Strategy
- Commit after each feature addition
- Use descriptive messages following existing pattern
- Include Claude Code attribution if desired

### Branching (if needed)
```bash
git checkout -b feature/playlist-support
# Make changes
git commit -m "Add playlist support with queue management"
git checkout master
git merge feature/playlist-support
```

## AVFoundation Notes

### Supported Formats
- **Audio**: Anything `AVAudioPlayer` supports (MP3, AAC, M4A, FLAC, WAV, AIFF, ALAC)
- **Video**: Anything `AVPlayer` supports (MP4, MOV, M4V with H.264/HEVC)
- OGG/Opus **NOT** supported natively

### File Type Detection
Using `UniformTypeIdentifiers`:
```swift
panel.allowedContentTypes = [.audiovisualContent, .audio, .movie, .video, .mpeg4Movie]
```

### Player Lifecycle
1. Create `AVAsset` from URL
2. Create `AVPlayerItem` from asset
3. Create `AVPlayer` from playerItem
4. Add observers (status, time)
5. Call `play()` to start
6. Clean up observers in `deinit`

## SwiftUI Patterns Used

### State Management
- `@StateObject` for ownership (in App)
- `@EnvironmentObject` for dependency injection
- `@Published` for observable properties

### Layout
- `VStack`, `HStack` for arrangement
- `.frame()` for sizing constraints
- `.padding()` for spacing

### Conditional Views
```swift
if condition {
    ViewA()
} else {
    ViewB()
}
```

## Future AI Assistant Notes

### When Making Changes
1. **Read files first** - Always use Read tool before editing
2. **Test builds** - Run `xcodebuild` after significant changes
3. **Check compatibility** - Verify macOS 12.0 compatibility
4. **Update this file** - Add notes about new features/patterns

### Common Requests & Solutions

**"Add dark mode support"**
- SwiftUI supports dark mode automatically
- Can customize with `.preferredColorScheme()` modifier

**"Make UI look better"**
- Adjust spacing, padding, colors
- Add SF Symbols icons (already using some)
- Consider macOS design guidelines

**"Add more timer presets"**
- Edit `presetDurations` array in `SleepTimerView.swift`
- Add more tuples: `("90 min", 90 * 60)`

**"Support more file formats"**
- AVFoundation limitation - can't add OGG/Opus without external library
- Could integrate FFmpeg but significantly increases complexity

### Debugging Tips
- Use Xcode's debugger (breakpoints)
- Add `print()` statements in Services for logging
- Check Console.app for crash logs
- Use Instruments for performance profiling

## References

- [AVFoundation Documentation](https://developer.apple.com/av-foundation/)
- [SwiftUI Documentation](https://developer.apple.com/xcode/swiftui/)
- [MPRemoteCommandCenter](https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter)

---

**Last Updated**: 2025-12-26
**Project Version**: 1.0.1 (AirPods media control fix)
**Build Status**: ✅ Builds successfully with Xcode 13.4+

## Recent Updates

### 2025-12-26 - AirPods Media Control Fix
- Fixed AirPods button integration by implementing proper Now Playing Info updates
- Added explicit `playbackState` setting to claim media control priority
- Updated Info.plist with `LSApplicationCategoryType` = `public.app-category.music`
- All Now Playing updates now happen on main thread for stability
- Media control is claimed immediately when loading and playing files
