//
//  VideoPlayer.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/24.
//
import UIKit
import AVFoundation

class VideoPlayer: UIView {
    
    // MARK: - Properties
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    
    private let controlView = VideoPlayerControlView()
    private var isFullscreen = false
    private var originalFrame: CGRect = .zero
    
    var videoURL: URL? {
        didSet {
            setupPlayer()
        }
    }
    
    var qualities: [VideoQuality] = [] {
        didSet {
            // Update quality button visibility
            controlView.isHidden = qualities.isEmpty
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .black
        clipsToBounds = true
        
        // Add control view
        controlView.delegate = self
        addSubview(controlView)
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controlView.topAnchor.constraint(equalTo: topAnchor),
            controlView.bottomAnchor.constraint(equalTo: bottomAnchor),
            controlView.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // 单机手势
        let tapGesture = UITapGestureRecognizer()
        tapGesture.numberOfTapsRequired = 1
        tapGesture.addTarget(self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Player Setup
    private func setupPlayer() {
        guard let url = videoURL else { return }
        
        // Remove previous player
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        removeObservers()
        
        // Create new player
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = bounds
        layer.insertSublayer(playerLayer!, at: 0)
        
        // Add observers
        addObservers()
        
        // Start playback
        player?.play()
        controlView.updatePlaybackStatus(isPlaying: true)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // 显示/隐藏控制面板
        UIView.animate(withDuration: 0.3) {
            self.controlView.alpha = self.controlView.alpha == 0 ? 1 : 0
        }
        
        // 3秒后自动隐藏
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideControls), object: nil)
        perform(#selector(hideControls), with: nil, afterDelay: 3.0)
    }
    
    @objc func hideControls() {
        UIView.animate(withDuration: 0.3) {
            self.controlView.alpha = 0
        }
    }
    
    // MARK: - Observers
    private func addObservers() {
       
        addTimeObserver()
        
        // Notification observers
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func addTimeObserver() {
        // Time observer for progress updates
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            if self.controlView.isSliding {
                print("滑动拦截")
                return
            }
            
            let currentTime = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(self.playerItem?.duration ?? CMTime.zero)
            
            if !duration.isNaN {
                self.controlView.updateTime(currentTime: currentTime, duration: duration)
            }
            
            // Update buffered time
            if let loadedRanges = self.playerItem?.loadedTimeRanges.first {
                let bufferedTime = CMTimeGetSeconds(loadedRanges.timeRangeValue.start) + CMTimeGetSeconds(loadedRanges.timeRangeValue.duration)
                self.controlView.updateBufferedTime(bufferedTime: bufferedTime)
            }
        }
        
    }
    
    private func removeTimeObserver() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    private func removeObservers() {
        removeTimeObserver()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    // MARK: - Notification Handlers
    @objc private func playerItemDidPlayToEndTime() {
        player?.seek(to: CMTime.zero)
        controlView.updatePlaybackStatus(isPlaying: false)
    }
    
    @objc private func applicationWillResignActive() {
        player?.pause()
        controlView.updatePlaybackStatus(isPlaying: false)
    }
    
    @objc private func applicationDidBecomeActive() {
        if controlView.isPlaying {
            player?.play()
        }
    }
    
    // MARK: - Public Methods
    func play() {
        player?.play()
        controlView.updatePlaybackStatus(isPlaying: true)
    }
    
    func pause() {
        player?.pause()
        controlView.updatePlaybackStatus(isPlaying: false)
    }
    
    func toggleFullscreen() {
        guard let superview = superview else { return }
        
        if isFullscreen {
            // 退出全屏
            UIView.animate(withDuration: 0.3) {
                self.transform = .identity
                self.frame = self.originalFrame
                superview.layoutIfNeeded()
            }
        } else {
            // 进入全屏
            originalFrame = frame
            let fullscreenFrame = superview.convert(superview.bounds, to: nil)
            
            UIView.animate(withDuration: 0.3) {
                self.transform = CGAffineTransform(rotationAngle: .pi/2)
                self.frame = fullscreenFrame
                superview.layoutIfNeeded()
            }
        }
        
        isFullscreen = !isFullscreen
        controlView.updateFullscreenStatus(isFullscreen: isFullscreen)
        
        // 确保控制面板可见
        UIView.animate(withDuration: 0.3) {
            self.controlView.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.hideControls()
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func forward(seconds: TimeInterval = 10) {
        guard let currentTime = player?.currentTime() else { return }
        let newTime = CMTimeGetSeconds(currentTime) + seconds
        let duration = CMTimeGetSeconds(playerItem?.duration ?? CMTime.zero)
        
        if newTime < duration {
            seek(to: newTime)
        } else {
            seek(to: duration)
        }
    }
    
    func backward(seconds: TimeInterval = 10) {
        guard let currentTime = player?.currentTime() else { return }
        let newTime = max(CMTimeGetSeconds(currentTime) - seconds, 0)
        seek(to: newTime)
    }
    
    func changeQuality(to quality: VideoQuality) {
        videoURL = quality.url
    }
}

// MARK: - VideoPlayerControlViewDelegate
extension VideoPlayer: VideoPlayerControlViewDelegate {
    func controlViewDidTapPlayPause(_ controlView: VideoPlayerControlView) {
        if controlView.isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // 在VideoPlayerControlViewDelegate扩展中处理全屏按钮点击
    func controlViewDidTapFullscreen(_ controlView: VideoPlayerControlView) {
        toggleFullscreen()
    }
    
    func controlView(_ controlView: VideoPlayerControlView, didSelectQuality quality: VideoQuality) {
        changeQuality(to: quality)
    }
    
    func controlView(_ controlView: VideoPlayerControlView, isSeekingTo time: TimeInterval) {
        seek(to: time)
//        removeTimeObserver()
    }
    
    func controlView(_ controlView: VideoPlayerControlView, didSeekTo time: TimeInterval) {
        seek(to: time)
//        addTimeObserver()
    }
    
    func controlViewDidTapBackward(_ controlView: VideoPlayerControlView) {
        backward()
    }
    
    func controlViewDidTapForward(_ controlView: VideoPlayerControlView) {
        forward()
    }
}
