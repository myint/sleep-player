import SwiftUI

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
                .frame(minWidth: 600, minHeight: 500)
                .onAppear {
                    // Wire up the media key handler and sleep timer service
                    mediaKeyHandler.setMediaPlayerState(mediaPlayerState)
                    sleepTimerState.sleepTimerService?.setMediaPlayerState(mediaPlayerState)
                }
        }
    }
}
