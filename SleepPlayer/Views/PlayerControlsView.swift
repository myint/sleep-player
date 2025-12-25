import SwiftUI

struct PlayerControlsView: View {
    @EnvironmentObject var mediaPlayerState: MediaPlayerState

    var body: some View {
        VStack(spacing: 15) {
            // Time display
            HStack {
                Text(formatTime(mediaPlayerState.currentTime))
                    .font(.system(.body, design: .monospaced))

                Spacer()

                Text(formatTime(mediaPlayerState.duration))
                    .font(.system(.body, design: .monospaced))
            }
            .foregroundColor(.secondary)

            // Progress bar
            Slider(
                value: Binding(
                    get: { mediaPlayerState.currentTime },
                    set: { newValue in
                        mediaPlayerState.seek(to: newValue)
                    }
                ),
                in: 0...max(mediaPlayerState.duration, 1)
            )

            // Control buttons
            HStack(spacing: 20) {
                // Play/Pause button
                Button(action: {
                    if mediaPlayerState.playbackState == .playing {
                        mediaPlayerState.pause()
                    } else {
                        mediaPlayerState.play()
                    }
                }) {
                    Image(systemName: mediaPlayerState.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }
                .buttonStyle(.plain)
                .disabled(mediaPlayerState.currentFileURL == nil)
                .keyboardShortcut(.space, modifiers: [])

                Spacer()

                // Volume control
                HStack {
                    Image(systemName: "speaker.fill")
                    Slider(
                        value: Binding(
                            get: { mediaPlayerState.volume },
                            set: { newValue in
                                mediaPlayerState.setVolume(Float(newValue))
                            }
                        ),
                        in: 0...1
                    )
                    .frame(width: 100)
                }
            }
            .padding(.vertical, 5)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && seconds.isFinite else {
            return "00:00"
        }

        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct PlayerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerControlsView()
            .environmentObject(MediaPlayerState())
    }
}
