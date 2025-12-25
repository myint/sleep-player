# Sleep Timer Media Player

A native macOS media player with sleep timer functionality, supporting both audio and video playback with AirPod button integration.

## Features

- **Audio & Video Playback**: Supports all AVFoundation-native formats (MP3, M4A, FLAC, WAV, AIFF for audio; MP4, MOV, M4V for video)
- **Sleep Timer**: Configurable timer (default 30 minutes) with preset options (15, 30, 45, 60 minutes)
- **Smooth Fade Out**: Gradually reduces volume over 8 seconds before pausing playback
- **AirPod Integration**: Control playback using AirPod buttons
- **Clean UI**: Native SwiftUI interface for macOS

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 13.4 or later
- Swift 5.9+

## Setup Instructions

### Quick Start (Recommended)

The Xcode project is already set up and ready to use!

1. Open the project:
   ```bash
   open SleepPlayer.xcodeproj
   ```

2. In Xcode, select the "SleepPlayer" scheme at the top

3. Build and run (⌘R)

That's it! The app should launch with a clean window ready to load media files.

### Building from Command Line

You can also build from the command line:

```bash
xcodebuild -project SleepPlayer.xcodeproj -scheme SleepPlayer -configuration Debug build
```

To run the built app:

```bash
open ~/Library/Developer/Xcode/DerivedData/SleepPlayer-*/Build/Products/Debug/SleepPlayer.app
```

## Project Structure

```
SleepPlayer/
├── App/
│   └── SleepPlayerApp.swift          # App entry point
├── Models/
│   ├── MediaPlayerState.swift        # Player state management
│   └── SleepTimerState.swift         # Timer state management
├── Services/
│   ├── MediaPlayerService.swift      # AVPlayer integration
│   ├── SleepTimerService.swift       # Timer and fade logic
│   └── MediaKeyHandler.swift         # AirPod button handling
├── Views/
│   ├── ContentView.swift             # Main UI container
│   ├── VideoPlayerView.swift         # Video display
│   ├── PlayerControlsView.swift      # Playback controls
│   └── SleepTimerView.swift          # Timer UI
└── Assets.xcassets/                  # App icons and assets
```

## Usage

1. **Load Media**: Click "Open File" or press ⌘O to select an audio or video file
2. **Playback Controls**:
   - Press Space or click Play to start playback
   - Use the volume slider to adjust volume
   - Seek through media using the progress bar
3. **Sleep Timer**:
   - Click a preset button (15, 30, 45, or 60 minutes) to start the timer
   - Or click "Start Timer (30 min)" for the default duration
   - The timer will count down and fade out playback when it reaches zero
   - Click "Cancel Timer" to stop the timer early
4. **AirPod Controls**:
   - Press play/pause on your AirPods to control playback

## Technical Details

### Architecture
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (declarative UI)
- **Media Playback**: AVFoundation (AVPlayer for unified audio/video)
- **Remote Control**: MediaPlayer framework (MPRemoteCommandCenter)
- **Deployment Target**: macOS 12.0 (Monterey)

### Key Components
- **MediaPlayerService**: Manages AVPlayer, handles audio/video detection
- **SleepTimerService**: Countdown timer with 80-step volume fade (0.1s intervals)
- **MediaKeyHandler**: Registers remote command handlers for AirPods
- **State Management**: Observable objects with @Published properties

### Supported Formats
- **Audio**: MP3, AAC, M4A, FLAC, WAV, AIFF, ALAC, and all AVFoundation-supported audio
- **Video**: MP4, MOV, M4V, and all AVFoundation-supported video codecs

## Known Limitations

- Single file playback only (no playlists)
- No persistence between launches (fresh start each time)
- Requires macOS 12.0 or later
- Video player controls are custom (SwiftUI VideoPlayer used but controls disabled)

## Future Enhancements

Potential features for future development:
- [ ] Playlist support with queue management
- [ ] Persist last file, timer duration, and playback position
- [ ] Custom timer duration input (not just presets)
- [ ] Keyboard shortcuts for timer control
- [ ] Album art display for audio files
- [ ] Visualizer for audio playback
- [ ] Export timer history/usage statistics
- [ ] Mini player mode
- [ ] AppleScript support for automation

## Troubleshooting

### AirPod buttons not working
- Ensure the app is the active audio source
- Try playing media first, then test AirPod buttons
- Check that media key handlers are properly initialized

### Video not displaying
- Ensure the file is a valid video format
- Check that VideoPlayer is properly receiving the AVPlayer instance

### Build errors
- Verify minimum deployment target is set to macOS 12.0
- Ensure all source files are added to the app target
- Clean build folder (⌘⇧K) and rebuild

## License

Copyright © 2025. All rights reserved.
