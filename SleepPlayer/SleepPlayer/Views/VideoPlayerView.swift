import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @EnvironmentObject var mediaPlayerState: MediaPlayerState

    var body: some View {
        if let player = mediaPlayerState.getPlayer() {
            VideoPlayer(player: player)
                .aspectRatio(16/9, contentMode: .fit)
                .disabled(true) // Disable default video player controls
        } else {
            Rectangle()
                .fill(Color.black)
                .overlay(
                    Text("No video loaded")
                        .foregroundColor(.white)
                )
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView()
            .environmentObject(MediaPlayerState())
            .frame(height: 300)
    }
}
