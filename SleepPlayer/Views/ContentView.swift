import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var mediaPlayerState: MediaPlayerState
    @EnvironmentObject var sleepTimerState: SleepTimerState

    var body: some View {
        VStack(spacing: 15) {
            // Header - only show when no media is loaded
            if mediaPlayerState.currentFileURL == nil {
                Text("Sleep Timer Media Player")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 10)
            }

            // Video Player View (conditional)
            if mediaPlayerState.mediaType == .video {
                VideoPlayerView()
                    .frame(height: 300)
                    .cornerRadius(8)
            } else if mediaPlayerState.currentFileURL != nil {
                // Audio placeholder
                VStack {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Audio Playing")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            // File name display
            if !mediaPlayerState.currentFileName.isEmpty {
                Text(mediaPlayerState.currentFileName)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal)
            }

            // Player Controls
            PlayerControlsView()
                .padding(.horizontal)

            Divider()
                .padding(.vertical, 5)

            // Sleep Timer
            SleepTimerView()
        }
        .padding()
        .fixedSize(horizontal: false, vertical: true)
        .alert("Error Loading Media", isPresented: .constant(mediaPlayerState.errorMessage != nil), actions: {
            Button("OK") {
                mediaPlayerState.errorMessage = nil
            }
        }, message: {
            Text(mediaPlayerState.errorMessage ?? "Unknown error occurred")
        })
        .onDisappear {
            // When window closes, fully clear media and cancel timer
            mediaPlayerState.clearMedia()
            sleepTimerState.cancelTimer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MediaPlayerState())
            .environmentObject(SleepTimerState())
    }
}
