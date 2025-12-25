import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    @EnvironmentObject var mediaPlayerState: MediaPlayerState

    var body: some View {
        if let player = mediaPlayerState.getPlayer() {
            AVPlayerViewRepresentable(player: player)
                .aspectRatio(16/9, contentMode: .fit)
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

// NSViewRepresentable wrapper for AVPlayerView
struct AVPlayerViewRepresentable: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .none
        playerView.showsFullScreenToggleButton = false
        return playerView
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView()
            .environmentObject(MediaPlayerState())
            .frame(height: 300)
    }
}
