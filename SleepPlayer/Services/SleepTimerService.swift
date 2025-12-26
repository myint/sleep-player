import Foundation
import Combine

class SleepTimerService {
    private weak var state: SleepTimerState?
    private var timer: Timer?
    private var fadeTimer: Timer?
    private var mediaPlayerState: MediaPlayerState?
    private var volumeBeforeFade: Float = 1.0

    init(state: SleepTimerState) {
        self.state = state
    }

    func setMediaPlayerState(_ mediaPlayerState: MediaPlayerState) {
        self.mediaPlayerState = mediaPlayerState
    }

    func start(duration: TimeInterval) {
        cancel() // Cancel any existing timer

        guard state != nil else { return }

        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let state = self.state else { return }

            // Update state asynchronously to avoid interfering with menu tracking
            DispatchQueue.main.async {
                if !state.isPaused && state.remainingTime > 0 {
                    state.remainingTime -= 1

                    // Start fade when remaining time reaches fade duration
                    if !state.isFading && state.remainingTime <= state.fadeDuration {
                        self.startFadeOut()
                    }
                } else if !state.isPaused && state.remainingTime <= 0 {
                    self.timerExpired()
                }
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    func pause() {
        // Keep timer running but stop decrementing in the timer callback
        // State's isPaused property will be checked in the timer callback
    }

    func resume() {
        // Resume decrementing - state's isPaused will be set to false
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        fadeTimer?.invalidate()
        fadeTimer = nil

        // Restore volume to what it was before fade started (only if we were fading)
        if state?.isFading == true, let mediaPlayerState = mediaPlayerState {
            mediaPlayerState.setVolume(volumeBeforeFade)
        }

        state?.isFading = false
    }

    func triggerEndOfFileFade() {
        // Called when file is near end - start fade-out
        startFadeOut()
    }

    private func timerExpired() {
        // Only invalidate the countdown timer, NOT the fade timer
        // The fade timer should be allowed to complete
        timer?.invalidate()
        timer = nil

        // If fade hasn't started yet (shouldn't happen), start it now
        if let state = state, !state.isFading {
            startFadeOut()
        }
    }

    private func startFadeOut() {
        guard let mediaPlayerState = mediaPlayerState, let state = state else { return }

        // Don't start a new fade if one is already running
        if fadeTimer != nil {
            return
        }

        // Ensure minimum fade duration to prevent division by zero
        let fadeDuration = max(state.fadeDuration, 1.0)
        let fadeSteps = Int(fadeDuration * 10) // 0.1s intervals

        // Guard against zero fade steps (shouldn't happen with min duration, but be safe)
        guard fadeSteps > 0 else { return }

        // Save current volume before fading
        let initialVolume = mediaPlayerState.volume
        volumeBeforeFade = initialVolume

        // Mark that we're fading - only do this AFTER the guards pass
        state.isFading = true

        let volumeStep = initialVolume / Float(fadeSteps)
        var currentStep = 0

        let newFadeTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let mediaPlayerState = self.mediaPlayerState else {
                timer.invalidate()
                return
            }

            // Check if playback is still active - cancel fade if stopped or manually paused
            if mediaPlayerState.playbackState != .playing {
                timer.invalidate()
                self.fadeTimer = nil
                if let state = self.state {
                    state.isFading = false
                }
                return
            }

            currentStep += 1

            if currentStep >= fadeSteps {
                // Fade complete - pause playback
                mediaPlayerState.setVolume(0)
                mediaPlayerState.pause()
                timer.invalidate()
                self.fadeTimer = nil

                // Clean up state
                if let state = self.state {
                    state.isFading = false
                    state.isActive = false
                }

                // Reset volume to pre-fade level for next playback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    mediaPlayerState.setVolume(self.volumeBeforeFade)
                }
            } else {
                // Reduce volume gradually
                let newVolume = max(0, mediaPlayerState.volume - volumeStep)
                mediaPlayerState.setVolume(newVolume)
            }
        }
        RunLoop.main.add(newFadeTimer, forMode: .common)
        fadeTimer = newFadeTimer
    }

    deinit {
        cancel()
    }
}
