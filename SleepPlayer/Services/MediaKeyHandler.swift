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
        // Ensure command center setup happens on main thread
        DispatchQueue.main.async {
            let commandCenter = MPRemoteCommandCenter.shared()

            // Play command
            commandCenter.playCommand.isEnabled = true
            let playTarget = commandCenter.playCommand.addTarget { [weak self] event in
                DispatchQueue.main.async {
                    self?.mediaPlayerState?.play()
                }
                return .success
            }
            self.commandTargets.append(playTarget)

            // Pause command
            commandCenter.pauseCommand.isEnabled = true
            let pauseTarget = commandCenter.pauseCommand.addTarget { [weak self] event in
                DispatchQueue.main.async {
                    self?.mediaPlayerState?.pause()
                }
                return .success
            }
            self.commandTargets.append(pauseTarget)

            // Toggle play/pause command
            commandCenter.togglePlayPauseCommand.isEnabled = true
            let toggleTarget = commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
                guard let self = self, let state = self.mediaPlayerState else {
                    return .commandFailed
                }

                DispatchQueue.main.async {
                    if state.playbackState == .playing {
                        state.pause()
                    } else {
                        state.play()
                    }
                }
                return .success
            }
            self.commandTargets.append(toggleTarget)
        }
    }

    func updateNowPlayingInfo(title: String, duration: TimeInterval, currentTime: TimeInterval, playbackRate: Float = 1.0) {
        // Ensure Now Playing updates happen on main thread
        DispatchQueue.main.async {
            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyTitle] = title
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate

            let nowPlayingCenter = MPNowPlayingInfoCenter.default()
            nowPlayingCenter.nowPlayingInfo = nowPlayingInfo

            // Set playback state to claim media control priority on macOS
            if playbackRate > 0 {
                nowPlayingCenter.playbackState = .playing
            } else {
                nowPlayingCenter.playbackState = .paused
            }
        }
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
