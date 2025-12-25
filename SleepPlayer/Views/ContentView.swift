import SwiftUI

struct ContentView: View {
    @EnvironmentObject var mediaPlayerState: MediaPlayerState
    @EnvironmentObject var sleepTimerState: SleepTimerState

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Sleep Timer Media Player")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)

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
            }

            Divider()

            // Sleep Timer
            SleepTimerView()

            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MediaPlayerState())
            .environmentObject(SleepTimerState())
    }
}
