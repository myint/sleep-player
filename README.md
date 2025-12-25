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

### Option 1: Create Xcode Project (Recommended)

1. Open Xcode
2. Select "File" → "New" → "Project"
3. Choose "macOS" → "App"
4. Configure the project:
   - Product Name: **SleepPlayer**
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Save to: The `sleep-player` directory

5. Delete the default files created by Xcode (ContentView.swift, SleepPlayerApp.swift, etc.)

6. Add the source files to your project:
   - Right-click on the "SleepPlayer" group in Xcode
   - Select "Add Files to SleepPlayer..."
   - Navigate to `SleepPlayer/SleepPlayer/` and add all folders:
     - App/
     - Models/
     - Services/
     - Views/
     - Assets.xcassets/
   - Make sure "Copy items if needed" is **unchecked**
   - Make sure target is checked

7. Set deployment target:
   - Select the project in the navigator
   - Under "Deployment Info", set "Minimum Deployments" to **macOS 12.0**

8. Build and run (⌘R)

### Option 2: Import Existing Files

If you have an existing Xcode project:

1. Drag the folders from `SleepPlayer/SleepPlayer/` into your Xcode project
2. Ensure all files are added to your target
3. Set minimum deployment target to macOS 12.0

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

- Built with **Swift** and **SwiftUI**
- Uses **AVFoundation** for media playback
- **MediaPlayer** framework for AirPod integration
- Sleep timer uses volume interpolation for smooth 8-second fade-out
- Video conditionally displayed only for video files

## Known Limitations

- Single file playback only (no playlists)
- No persistence between launches (fresh start each time)
- Requires macOS 12.0 or later

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
