import SwiftUI
import UniformTypeIdentifiers
import AppKit

// AppDelegate to handle file opening
class AppDelegate: NSObject, NSApplicationDelegate {
    var fileURLToOpen: URL?
    var pendingFileURL: URL?

    func application(_ application: NSApplication, open urls: [URL]) {
        // Store the first URL to be processed when the app is ready
        if let url = urls.first {
            fileURLToOpen = url

            // Activate the app
            NSApp.activate(ignoringOtherApps: true)

            // Check if we have any visible windows
            let hasVisibleWindow = NSApp.windows.contains(where: { $0.isVisible })

            if !hasVisibleWindow {
                // No visible window - store for loading when window appears
                pendingFileURL = url
                if let bundleURL = Bundle.main.bundleURL as URL? {
                    let config = NSWorkspace.OpenConfiguration()
                    config.activates = true
                    config.createsNewApplicationInstance = false
                    NSWorkspace.shared.openApplication(at: bundleURL, configuration: config) { _, error in
                        if let error = error {
                            print("Error reopening app: \(error)")
                        }
                    }
                }
            } else {
                // Window exists, just post notification to load file
                NotificationCenter.default.post(name: .requestOpenFile, object: url)
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // If a file was queued to open, store it for when window appears
        if let url = fileURLToOpen {
            pendingFileURL = url
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // The pending file will be loaded when ContentView appears
        return true
    }
}

extension Notification.Name {
    static let openMediaFile = Notification.Name("openMediaFile")
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
                            // Show window if hidden/closed
                            NSApp.windows.first?.makeKeyAndOrderFront(nil)
                            // Load media
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
                // Check if we have any visible windows
                let hasVisibleWindow = NSApp.windows.contains(where: { $0.isVisible })

                if !hasVisibleWindow {
                    // No visible window - trigger the same reopen mechanism as file associations
                    self.appDelegate.pendingFileURL = url
                    if let bundleURL = Bundle.main.bundleURL as URL? {
                        let config = NSWorkspace.OpenConfiguration()
                        config.activates = true
                        config.createsNewApplicationInstance = false
                        NSWorkspace.shared.openApplication(at: bundleURL, configuration: config) { _, error in
                            if let error = error {
                                print("Error reopening app: \(error)")
                                // Fallback: just load the media
                                DispatchQueue.main.async {
                                    self.mediaPlayerState.loadMedia(url: url)
                                }
                            }
                        }
                    }
                } else {
                    // Window exists, load directly
                    self.mediaPlayerState.loadMedia(url: url)
                }
            }
        }
    }
}
