import Foundation
import MediaPlayer
import Combine

class MediaKeyHandler: ObservableObject {
    private var mediaPlayerState: MediaPlayerState?
    private var commandTargets: [Any] = []

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
        let playTarget = commandCenter.playCommand.addTarget { [weak self] event in
            self?.mediaPlayerState?.play()
            return .success
        }
        commandTargets.append(playTarget)

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        let pauseTarget = commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.mediaPlayerState?.pause()
            return .success
        }
        commandTargets.append(pauseTarget)

        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        let toggleTarget = commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
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
        commandTargets.append(toggleTarget)
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

        // Remove only the specific targets this instance added
        for target in commandTargets {
            commandCenter.playCommand.removeTarget(target)
            commandCenter.pauseCommand.removeTarget(target)
            commandCenter.togglePlayPauseCommand.removeTarget(target)
        }

        commandTargets.removeAll()
    }
}
