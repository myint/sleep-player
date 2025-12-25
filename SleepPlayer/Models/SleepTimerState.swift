import Foundation
import Combine

class SleepTimerState: ObservableObject {
    @Published var timerDuration: TimeInterval = 30 * 60 // Default 30 minutes
    var remainingTime: TimeInterval = 0  // Not published to avoid menu issues
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false

    var sleepTimerService: SleepTimerService?

    init() {
        sleepTimerService = SleepTimerService(state: self)
    }

    func startTimer(duration: TimeInterval? = nil) {
        if let duration = duration {
            timerDuration = duration
        }
        remainingTime = timerDuration
        isActive = true
        isPaused = false
        sleepTimerService?.start(duration: timerDuration)
    }

    func pauseTimer() {
        isPaused = true
        sleepTimerService?.pause()
    }

    func resumeTimer() {
        isPaused = false
        sleepTimerService?.resume()
    }

    func cancelTimer() {
        isActive = false
        isPaused = false
        remainingTime = 0
        sleepTimerService?.cancel()
    }

    func resetTimer() {
        // Reset timer to configured duration while maintaining active state
        let wasActive = isActive
        let wasPaused = isPaused

        remainingTime = timerDuration

        if wasActive {
            // Restart the timer with the new remaining time
            sleepTimerService?.cancel()
            isActive = true
            isPaused = wasPaused
            sleepTimerService?.start(duration: timerDuration)

            if wasPaused {
                sleepTimerService?.pause()
            }
        }
    }

    var remainingTimeFormatted: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
