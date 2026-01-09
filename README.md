# Sleep Timer Media Player

A native macOS media player with configurable sleep timer, supporting both audio and video playback with AirPods button integration.

## Features

- **Audio & Video**: All AVFoundation formats (MP3, M4A, FLAC, WAV, MP4, MOV, etc.)
- **Configurable Sleep Timer**: 1-120 minutes (default 20 min), auto-starts with playback
- **Smooth Fade Out**: Configurable 5-120 seconds (default 60s), with end-of-file detection
- **AirPods Integration**: Play/pause control via AirPods buttons
- **File Associations**: Double-click media files to open
- **Auto-play**: Files start playing immediately when loaded
- **Volume Reset**: Always resets to 100% for consistent fade behavior

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 13.4+ and Swift 5.9+ (for building from source)

## Installation

### From Source

```bash
# Open in Xcode and run
open SleepPlayer.xcodeproj

# Or build from command line
make build
make install  # Copies to /Applications
```

### Using Makefile

```bash
make help      # Show all commands
make build     # Build release version
make run       # Build and run
make dmg       # Create distributable DMG
make clean     # Clean build artifacts
```

## Usage

1. **Load Media**: Press ⌘O, click the play button, or double-click a media file
2. **Playback**: Space to play/pause, arrow keys to seek ±5 seconds
3. **Sleep Timer**:
   - Configure duration (1-120 min) and fade time (5-120s) using steppers
   - Timer auto-starts with playback and pauses when you pause
   - Reset button restarts countdown
   - Set "Stop before end" to fade out before media finishes
4. **AirPods**: Play/pause buttons work automatically

## Architecture

- **Swift 5.9+ / SwiftUI** - MVVM pattern with Observable state objects
- **AVFoundation** - AVPlayer for unified audio/video playback
- **MediaPlayer** - MPRemoteCommandCenter for AirPods integration
- **Key Services**:
  - `MediaPlayerService` - AVPlayer wrapper with audio/video detection
  - `SleepTimerService` - Countdown timer with dynamic volume fade (fadeDuration × 10 steps at 0.1s intervals)
  - `MediaKeyHandler` - Remote command registration and Now Playing Info updates

## Troubleshooting

**AirPods buttons control wrong app**: Quit other media apps first. macOS prioritizes the most recently active player.

**Volume resets unexpectedly**: By design. Volume always resets to 100% when playing, pausing, or after fade-out for consistent behavior.

**App won't open**: Right-click → Open to bypass Gatekeeper (unsigned app).

**Build errors**: Ensure deployment target is macOS 12.0, clean build folder (⌘⇧K), and rebuild.

## Limitations

- Single file playback (no playlists)
- No persistence between launches
- App quits when window closes (QuickTime-style behavior)

## License

Copyright © 2025. All rights reserved.
