import SwiftUI
import UniformTypeIdentifiers

struct PlayerControlsView: View {
    @EnvironmentObject var mediaPlayerState: MediaPlayerState
    @State private var isShowingFilePicker = false

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
                // Open File button
                Button(action: {
                    openFilePicker()
                }) {
                    Label("Open File", systemImage: "folder")
                }
                .keyboardShortcut("o", modifiers: .command)

                Spacer()

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
                .disabled(mediaPlayerState.currentFileURL == nil)
                .keyboardShortcut(.space, modifiers: [])

                // Stop button
                Button(action: {
                    mediaPlayerState.stop()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 44))
                }
                .disabled(mediaPlayerState.currentFileURL == nil)

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
        }
        .padding(.horizontal)
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .audiovisualContent,
            .audio,
            .movie,
            .video,
            .mpeg4Movie,
            UTType(filenameExtension: "mp3")!,
            UTType(filenameExtension: "m4a")!,
            UTType(filenameExtension: "flac")!,
            UTType(filenameExtension: "wav")!
        ]

        if panel.runModal() == .OK, let url = panel.url {
            mediaPlayerState.loadMedia(url: url)
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
