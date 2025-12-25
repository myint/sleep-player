import Foundation
import Combine

class SleepTimerState: ObservableObject {
    @Published var timerDuration: TimeInterval = 30 * 60 // Default 30 minutes
    @Published var remainingTime: TimeInterval = 0
    @Published var isActive: Bool = false

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
        sleepTimerService?.start(duration: timerDuration)
    }

    func cancelTimer() {
        isActive = false
        remainingTime = 0
        sleepTimerService?.cancel()
    }

    func resetTimer() {
        cancelTimer()
        remainingTime = timerDuration
    }

    var remainingTimeFormatted: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
