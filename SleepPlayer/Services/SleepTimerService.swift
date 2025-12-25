import Foundation
import Combine

class SleepTimerService {
    private weak var state: SleepTimerState?
    private var timer: Timer?
    private var fadeTimer: Timer?
    private var mediaPlayerState: MediaPlayerState?

    init(state: SleepTimerState) {
        self.state = state
    }

    func setMediaPlayerState(_ mediaPlayerState: MediaPlayerState) {
        self.mediaPlayerState = mediaPlayerState
    }

    func start(duration: TimeInterval) {
        cancel() // Cancel any existing timer

        guard let state = state else { return }

        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let state = self.state else { return }

            // Update state asynchronously to avoid interfering with menu tracking
            DispatchQueue.main.async {
                if !state.isPaused && state.remainingTime > 0 {
                    state.remainingTime -= 1
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
    }

    private func timerExpired() {
        cancel()

        // Start fade-out
        startFadeOut()
    }

    private func startFadeOut() {
        guard let mediaPlayerState = mediaPlayerState else { return }

        let fadeDuration: TimeInterval = 8.0 // 8 seconds
        let fadeSteps = 80 // 0.1s intervals
        let volumeStep = mediaPlayerState.volume / Float(fadeSteps)
        var currentStep = 0

        let newFadeTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let mediaPlayerState = self.mediaPlayerState else {
                timer.invalidate()
                return
            }

            currentStep += 1

            if currentStep >= fadeSteps {
                // Fade complete - pause playback
                mediaPlayerState.setVolume(0)
                mediaPlayerState.pause()
                timer.invalidate()
                self.fadeTimer = nil

                // Reset volume for next playback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    mediaPlayerState.setVolume(1.0)
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
