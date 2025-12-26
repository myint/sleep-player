import Foundation
import AVFoundation
import Combine

enum PlaybackState {
    case stopped
    case playing
    case paused
}

enum MediaType {
    case audio
    case video
    case unknown
}

class MediaPlayerState: ObservableObject {
    @Published var currentFileURL: URL?
    @Published var currentFileName: String = ""
    @Published var mediaType: MediaType = .unknown
    @Published var playbackState: PlaybackState = .stopped
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 1.0
    @Published var errorMessage: String?

    private var mediaPlayerService: MediaPlayerService?
    private var cancellables = Set<AnyCancellable>()

    // Reference to sleep timer for auto-start/pause/reset
    weak var sleepTimerState: SleepTimerState?

    // Reference to media key handler for Now Playing updates
    weak var mediaKeyHandler: MediaKeyHandler?

    // Callback to request file picker (set by App)
    var onRequestFileOpen: (() -> Void)?

    init() {
        mediaPlayerService = MediaPlayerService(state: self)
    }

    func loadMedia(url: URL) {
        // Clear any previous errors
        errorMessage = nil

        currentFileURL = url
        currentFileName = url.lastPathComponent
        mediaPlayerService?.loadMedia(url: url)

        // Immediately claim media control by setting Now Playing Info
        // This happens even before playback starts to take priority over other apps
        mediaKeyHandler?.updateNowPlayingInfo(
            title: currentFileName,
            duration: 0, // Will be updated when duration is available
            currentTime: 0,
            playbackRate: 0.0
        )

        // Reset timer when loading new file
        sleepTimerState?.resetTimer()

        // Auto-play immediately after loading
        play()
    }

    func play() {
        mediaPlayerService?.play()
        // Don't set playbackState here - let the rate observer update it
        // This prevents race conditions between manual state updates and AVPlayer state

        // Immediately claim media control by updating Now Playing Info
        mediaKeyHandler?.updateNowPlayingInfo(
            title: currentFileName,
            duration: duration,
            currentTime: currentTime,
            playbackRate: 1.0  // Set to 1.0 to indicate playing
        )

        // Auto-start or resume timer when playing
        if let sleepTimerState = sleepTimerState {
            if !sleepTimerState.isActive {
                // Start timer with current duration
                sleepTimerState.startTimer()
            } else if sleepTimerState.isPaused {
                // Resume timer if it was paused
                sleepTimerState.resumeTimer()
            }
        }
    }

    func pause() {
        mediaPlayerService?.pause()
        // Don't set playbackState here - let the rate observer update it
        // This prevents race conditions between manual state updates and AVPlayer state

        // Update Now Playing Info to indicate paused state
        mediaKeyHandler?.updateNowPlayingInfo(
            title: currentFileName,
            duration: duration,
            currentTime: currentTime,
            playbackRate: 0.0  // Set to 0.0 to indicate paused
        )

        // Pause timer when pausing playback
        sleepTimerState?.pauseTimer()
    }

    func stop() {
        mediaPlayerService?.stop()
        playbackState = .stopped
        currentTime = 0
    }

    func seek(to time: TimeInterval) {
        mediaPlayerService?.seek(to: time)
    }

    func setVolume(_ newVolume: Float) {
        volume = newVolume
        mediaPlayerService?.setVolume(newVolume)
    }

    func getPlayer() -> AVPlayer? {
        return mediaPlayerService?.player
    }
}
