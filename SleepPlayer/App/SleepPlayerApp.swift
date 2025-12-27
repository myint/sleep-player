import SwiftUI
import UniformTypeIdentifiers
import AppKit

// AppDelegate to handle file opening
class AppDelegate: NSObject, NSApplicationDelegate {
    var pendingFileURL: URL?

    func application(_ application: NSApplication, open urls: [URL]) {
        // Store the first URL to be processed when the app is ready
        if let url = urls.first {
            // If app is already running with a window, just load the file
            if NSApp.windows.contains(where: { $0.isVisible }) {
                NotificationCenter.default.post(name: .requestOpenFile, object: url)
            } else {
                // App is launching or no window - store for loading when window appears
                pendingFileURL = url
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Nothing needed here - pendingFileURL will be checked when ContentView appears
    }
}

extension Notification.Name {
    static let requestOpenFile = Notification.Name("requestOpenFile")
}

@main
struct SleepPlayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var mediaPlayerState = MediaPlayerState()
    @StateObject private var sleepTimerState = SleepTimerState()
    @StateObject private var mediaKeyHandler = MediaKeyHandler()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(mediaPlayerState)
                .environmentObject(sleepTimerState)
                .frame(minWidth: 650)
                .onAppear {
                    // Wire up the media key handler and sleep timer service
                    mediaKeyHandler.setMediaPlayerState(mediaPlayerState)
                    sleepTimerState.sleepTimerService?.setMediaPlayerState(mediaPlayerState)

                    // Wire up bidirectional reference between media player and sleep timer
                    mediaPlayerState.sleepTimerState = sleepTimerState

                    // Wire up media key handler to media player for Now Playing updates
                    mediaPlayerState.mediaKeyHandler = mediaKeyHandler

                    // Wire up file picker callback
                    mediaPlayerState.onRequestFileOpen = openFilePicker

                    // Check if there's a pending file to load
                    if let url = appDelegate.pendingFileURL {
                        appDelegate.pendingFileURL = nil
                        mediaPlayerState.loadMedia(url: url)
                    }

                    // Listen for file opening requests
                    NotificationCenter.default.addObserver(
                        forName: .requestOpenFile,
                        object: nil,
                        queue: .main
                    ) { notification in
                        if let url = notification.object as? URL {
                            mediaPlayerState.loadMedia(url: url)
                        }
                    }
                }
                .handlesExternalEvents(preferring: Set(arrayLiteral: "main"), allowing: Set(arrayLiteral: "*"))
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "main"))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    openFilePicker()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandMenu("View") {
                Button("Seek Backward 5 Seconds") {
                    let newTime = max(0, mediaPlayerState.currentTime - 5.0)
                    mediaPlayerState.seek(to: newTime)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
                .disabled(mediaPlayerState.currentFileURL == nil)

                Button("Seek Forward 5 Seconds") {
                    let newTime = min(mediaPlayerState.duration, mediaPlayerState.currentTime + 5.0)
                    mediaPlayerState.seek(to: newTime)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .disabled(mediaPlayerState.currentFileURL == nil)
            }

            CommandGroup(replacing: .help) {
                Button("Sleep Player Help") {
                    if let url = URL(string: "https://github.com/myint/sleep-player") {
                        NSWorkspace.shared.open(url)
                    }
                }
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
                // Load the media file directly
                self.mediaPlayerState.loadMedia(url: url)
            }
        }
    }
}
