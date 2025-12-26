import SwiftUI
import UniformTypeIdentifiers

@main
struct SleepPlayerApp: App {
    @StateObject private var mediaPlayerState = MediaPlayerState()
    @StateObject private var sleepTimerState = SleepTimerState()
    @StateObject private var mediaKeyHandler = MediaKeyHandler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mediaPlayerState)
                .environmentObject(sleepTimerState)
                .frame(minWidth: 650, minHeight: 800)
                .onAppear {
                    // Wire up the media key handler and sleep timer service
                    mediaKeyHandler.setMediaPlayerState(mediaPlayerState)
                    sleepTimerState.sleepTimerService?.setMediaPlayerState(mediaPlayerState)

                    // Wire up bidirectional reference between media player and sleep timer
                    mediaPlayerState.sleepTimerState = sleepTimerState
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    openFilePicker()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }

    private func openFilePicker() {
        // Defer panel presentation to avoid menu timing issues
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true

            // Build list of allowed content types safely
            var allowedTypes: [UTType] = [.audiovisualContent, .audio, .movie, .video, .mpeg4Movie]

            // Add additional file types if they can be created
            let extensions = ["mp3", "m4a", "flac", "wav"]
            for ext in extensions {
                if let type = UTType(filenameExtension: ext) {
                    allowedTypes.append(type)
                }
            }

            panel.allowedContentTypes = allowedTypes

            if panel.runModal() == .OK, let url = panel.url {
                self.mediaPlayerState.loadMedia(url: url)
            }
        }
    }
}
