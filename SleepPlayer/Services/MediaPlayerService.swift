import Foundation
import AVFoundation
import Combine

class MediaPlayerService {
    var player: AVPlayer?
    private weak var state: MediaPlayerState?
    private var playerItemObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var hasTriggeredEndFade = false
    private var timeUpdateCounter = 0

    init(state: MediaPlayerState) {
        self.state = state
        setupAudioSession()
    }

    private func setupAudioSession() {
        #if os(macOS)
        // macOS doesn't use AVAudioSession the same way as iOS
        // Audio session setup is handled differently
        #endif
    }

    func loadMedia(url: URL) {
        // Clean up existing player
        cleanup()

        hasTriggeredEndFade = false

        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        player = AVPlayer(playerItem: playerItem)

        // Detect media type (audio vs video)
        detectMediaType(asset: asset)

        // Observe player item status
        playerItemObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self = self, let state = self.state else { return }

            switch item.status {
            case .readyToPlay:
                state.duration = item.duration.seconds
                state.errorMessage = nil
                // Now Playing Info will be set by play() method
            case .failed:
                let errorMsg = item.error?.localizedDescription ?? "Failed to load media file"
                state.errorMessage = errorMsg
                state.playbackState = .stopped
            case .unknown:
                break
            @unknown default:
                break
            }
        }

        // Observe playback rate changes (for video player controls)
        rateObserver = player?.observe(\.rate, options: [.new]) { [weak self] player, _ in
            guard let self = self, let state = self.state else { return }

            // Schedule in default mode only to avoid dismissing menus
            CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue as CFTypeRef) {
                if player.rate > 0 {
                    // Playing
                    if state.playbackState != .playing {
                        state.playbackState = .playing
                        // Auto-start or resume timer
                        if let sleepTimerState = state.sleepTimerState {
                            if !sleepTimerState.isActive {
                                sleepTimerState.startTimer()
                            } else if sleepTimerState.isPaused {
                                sleepTimerState.resumeTimer()
                            }
                        }
                    }
                } else {
                    // Paused
                    if state.playbackState == .playing {
                        state.playbackState = .paused
                        // Pause timer
                        state.sleepTimerState?.pauseTimer()
                    }
                }

                // Update Now Playing Info with current playback rate
                state.mediaKeyHandler?.updateNowPlayingInfo(
                    title: state.currentFileName,
                    duration: state.duration,
                    currentTime: state.currentTime,
                    playbackRate: player.rate
                )
            }
            CFRunLoopWakeUp(CFRunLoopGetMain())
        }

        // Add periodic time observer to update current time and check for end fade
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeUpdateCounter = 0
        let queue = DispatchQueue(label: "com.sleepplayer.timeobserver")
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: queue) { [weak self] time in
            guard let self = self, let state = self.state else { return }

            let currentTime = time.seconds

            // Update UI every second, using default mode only to avoid dismissing menus
            // Timeline updates will pause while menus are open, which is standard macOS behavior
            CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue as CFTypeRef) {
                state.currentTime = currentTime
            }
            CFRunLoopWakeUp(CFRunLoopGetMain())

            // Update Now Playing Info every 5 seconds to reduce overhead
            self.timeUpdateCounter += 1
            if self.timeUpdateCounter >= 5 {
                self.timeUpdateCounter = 0
                CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue as CFTypeRef) {
                    state.mediaKeyHandler?.updateNowPlayingInfo(
                        title: state.currentFileName,
                        duration: state.duration,
                        currentTime: currentTime,
                        playbackRate: self.player?.rate ?? 0.0
                    )
                }
                CFRunLoopWakeUp(CFRunLoopGetMain())
            }

            // Check if we should start fade-out near end of file
            if let sleepTimerState = state.sleepTimerState {
                let duration = state.duration
                let chopEndDuration = sleepTimerState.chopEndDuration
                let fadeDuration = sleepTimerState.fadeDuration
                let timeRemaining = duration - currentTime
                // Calculate when fade should start: chop end duration plus fade duration
                let fadeStartThreshold = chopEndDuration + fadeDuration

                // Reset the fade trigger if we're outside the fade zone
                // This allows seeking to re-trigger the end-of-file fade
                if timeRemaining > fadeStartThreshold {
                    self.hasTriggeredEndFade = false
                }

                // Start fade if we're within (chop end + fade) duration of the end
                // Only do this if duration is valid and we're actually playing
                // PRIORITY: End-of-file fade takes priority over sleep timer
                if !self.hasTriggeredEndFade && duration > 0 && timeRemaining > 0 && timeRemaining <= fadeStartThreshold {
                    self.hasTriggeredEndFade = true

                    // Trigger fade - schedule in default mode only
                    CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue as CFTypeRef) {
                        // Cancel any sleep timer fade in progress to prioritize end-of-file
                        if sleepTimerState.isFading {
                            sleepTimerState.sleepTimerService?.cancel()
                        }
                        sleepTimerState.sleepTimerService?.triggerEndOfFileFade()
                    }
                    CFRunLoopWakeUp(CFRunLoopGetMain())
                }
            }
        }

        // Set initial volume
        player?.volume = state?.volume ?? 1.0
    }

    private func detectMediaType(asset: AVAsset) {
        Task {
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                await MainActor.run {
                    if tracks.isEmpty {
                        state?.mediaType = .audio
                    } else {
                        state?.mediaType = .video
                    }
                }
            } catch {
                // Log error but default to audio (most common case)
                print("Error detecting media type: \(error.localizedDescription)")
                await MainActor.run {
                    state?.mediaType = .audio
                }
            }
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }

    func setVolume(_ volume: Float) {
        player?.volume = volume
    }

    private func cleanup() {
        playerItemObserver?.invalidate()
        playerItemObserver = nil
        rateObserver?.invalidate()
        rateObserver = nil
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        player = nil
        hasTriggeredEndFade = false
    }

    deinit {
        cleanup()
    }
}
