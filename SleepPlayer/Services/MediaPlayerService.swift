import Foundation
import AVFoundation
import Combine

class MediaPlayerService {
    var player: AVPlayer?
    private weak var state: MediaPlayerState?
    private var timeObserver: Any?
    private var playerItemObserver: NSKeyValueObservation?

    init(state: MediaPlayerState) {
        self.state = state
        setupAudioSession()
    }

    private func setupAudioSession() {
        #if os(macOS)
        // macOS doesn't use AVAudioSession the same way as iOS
        // Audio session setup is handled differently
        #endif
    }

    func loadMedia(url: URL) {
        // Clean up existing player
        cleanup()

        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        player = AVPlayer(playerItem: playerItem)

        // Detect media type (audio vs video)
        detectMediaType(asset: asset)

        // Observe player item status
        playerItemObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            if item.status == .readyToPlay {
                self?.state?.duration = item.duration.seconds
            }
        }

        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.state?.currentTime = time.seconds
        }

        // Set initial volume
        player?.volume = state?.volume ?? 1.0
    }

    private func detectMediaType(asset: AVAsset) {
        Task {
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                await MainActor.run {
                    if tracks.isEmpty {
                        state?.mediaType = .audio
                    } else {
                        state?.mediaType = .video
                    }
                }
            } catch {
                await MainActor.run {
                    state?.mediaType = .audio
                }
            }
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }

    func setVolume(_ volume: Float) {
        player?.volume = volume
    }

    private func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        playerItemObserver?.invalidate()
        playerItemObserver = nil
        player = nil
    }

    deinit {
        cleanup()
    }
}
