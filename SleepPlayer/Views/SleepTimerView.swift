import SwiftUI

struct SleepTimerView: View {
    @EnvironmentObject var sleepTimerState: SleepTimerState
    @EnvironmentObject var mediaPlayerState: MediaPlayerState

    @State private var durationMinutes: Int = 30
    @State private var fadeSeconds: Int = 120
    @State private var chopEndSeconds: Int = 120

    var body: some View {
        VStack(spacing: 15) {
            Text("Sleep Timer")
                .font(.headline)

            // Timer display
            Text(sleepTimerState.isActive || sleepTimerState.isPaused ? sleepTimerState.remainingTimeFormatted : "--:--")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(sleepTimerState.isPaused ? .secondary : .primary)

            // Duration spinner and reset button
            HStack(spacing: 10) {
                Text("Duration (minutes):")
                    .font(.subheadline)

                Stepper(value: Binding(
                    get: { durationMinutes },
                    set: { newValue in
                        let isIncrement = newValue > durationMinutes

                        if isIncrement {
                            // Going up
                            if durationMinutes == 1 {
                                durationMinutes = 5
                            } else {
                                // Round up to next multiple of 5
                                durationMinutes = min(120, ((durationMinutes / 5) + 1) * 5)
                            }
                        } else {
                            // Going down
                            if durationMinutes <= 5 {
                                durationMinutes = 1
                            } else {
                                // Round down to previous multiple of 5
                                durationMinutes = max(5, ((durationMinutes - 1) / 5) * 5)
                            }
                        }
                    }
                ), in: 1...120) {
                    Text("\(durationMinutes)")
                        .font(.body)
                        .frame(width: 50)
                        .monospacedDigit()
                }
                .onChange(of: durationMinutes) { newValue in
                    sleepTimerState.timerDuration = TimeInterval(newValue * 60)
                    // Reset remaining time to new duration
                    if sleepTimerState.isActive || sleepTimerState.isPaused {
                        sleepTimerState.remainingTime = TimeInterval(newValue * 60)
                    }
                }

                Spacer()

                // Reset button
                Button(action: {
                    sleepTimerState.resetTimer()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16))
                }
                .buttonStyle(.bordered)
                .help("Reset timer to duration")
            }

            // Fade duration spinner
            HStack(spacing: 10) {
                Text("Fade duration (seconds):")
                    .font(.subheadline)

                Stepper(value: $fadeSeconds, in: 5...120, step: 5) {
                    Text("\(fadeSeconds)")
                        .font(.body)
                        .frame(width: 50)
                        .monospacedDigit()
                }
                .onChange(of: fadeSeconds) { newValue in
                    sleepTimerState.fadeDuration = TimeInterval(newValue)
                }

                Spacer()
            }

            // Chop end duration spinner
            HStack(spacing: 10) {
                Text("Stop before end (seconds):")
                    .font(.subheadline)

                Stepper(value: $chopEndSeconds, in: 0...300, step: 10) {
                    Text("\(chopEndSeconds)")
                        .font(.body)
                        .frame(width: 50)
                        .monospacedDigit()
                }
                .onChange(of: chopEndSeconds) { newValue in
                    sleepTimerState.chopEndDuration = TimeInterval(newValue)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            // Initialize duration from current timer duration
            durationMinutes = Int(sleepTimerState.timerDuration / 60)
            fadeSeconds = Int(sleepTimerState.fadeDuration)
            chopEndSeconds = Int(sleepTimerState.chopEndDuration)
        }
    }
}

struct SleepTimerView_Previews: PreviewProvider {
    static var previews: some View {
        SleepTimerView()
            .environmentObject(SleepTimerState())
            .environmentObject(MediaPlayerState())
    }
}
