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

    private var mediaPlayerService: MediaPlayerService?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    // Reference to sleep timer for auto-start/pause/reset
    weak var sleepTimerState: SleepTimerState?

    init() {
        mediaPlayerService = MediaPlayerService(state: self)
    }

    func loadMedia(url: URL) {
        currentFileURL = url
        currentFileName = url.lastPathComponent
        mediaPlayerService?.loadMedia(url: url)

        // Reset timer when loading new file
        sleepTimerState?.resetTimer()

        // Auto-play immediately after loading
        play()
    }

    func play() {
        mediaPlayerService?.play()
        playbackState = .playing

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
        playbackState = .paused

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
