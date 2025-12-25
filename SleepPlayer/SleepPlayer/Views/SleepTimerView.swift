import SwiftUI

struct SleepTimerView: View {
    @EnvironmentObject var sleepTimerState: SleepTimerState
    @EnvironmentObject var mediaPlayerState: MediaPlayerState

    let presetDurations: [(String, TimeInterval)] = [
        ("15 min", 15 * 60),
        ("30 min", 30 * 60),
        ("45 min", 45 * 60),
        ("60 min", 60 * 60)
    ]

    var body: some View {
        VStack(spacing: 15) {
            Text("Sleep Timer")
                .font(.headline)

            // Timer display
            if sleepTimerState.isActive {
                Text(sleepTimerState.remainingTimeFormatted)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            } else {
                Text("--:--")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // Preset buttons
            HStack(spacing: 12) {
                ForEach(presetDurations, id: \.0) { preset in
                    Button(preset.0) {
                        if !sleepTimerState.isActive {
                            startTimerWithMediaPlayer(duration: preset.1)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(sleepTimerState.isActive)
                }
            }

            // Control buttons
            HStack(spacing: 20) {
                if sleepTimerState.isActive {
                    Button("Cancel Timer") {
                        sleepTimerState.cancelTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button("Start Timer (30 min)") {
                        startTimerWithMediaPlayer(duration: nil)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func startTimerWithMediaPlayer(duration: TimeInterval?) {
        // Connect the sleep timer service to the media player state
        if let sleepTimerService = sleepTimerState.sleepTimerService {
            sleepTimerService.setMediaPlayerState(mediaPlayerState)
        }

        sleepTimerState.startTimer(duration: duration)
    }
}

struct SleepTimerView_Previews: PreviewProvider {
    static var previews: some View {
        SleepTimerView()
            .environmentObject(SleepTimerState())
            .environmentObject(MediaPlayerState())
    }
}
