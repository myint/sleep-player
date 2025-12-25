import Foundation
import MediaPlayer
import Combine

class MediaKeyHandler: ObservableObject {
    private var mediaPlayerState: MediaPlayerState?

    init() {
        setupRemoteCommandCenter()
    }

    func setMediaPlayerState(_ state: MediaPlayerState) {
        self.mediaPlayerState = state
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.mediaPlayerState?.play()
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.mediaPlayerState?.pause()
            return .success
        }

        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            guard let self = self, let state = self.mediaPlayerState else {
                return .commandFailed
            }

            if state.playbackState == .playing {
                state.pause()
            } else {
                state.play()
            }
            return .success
        }
    }

    func updateNowPlayingInfo(title: String, duration: TimeInterval, currentTime: TimeInterval) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    deinit {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
    }
}
