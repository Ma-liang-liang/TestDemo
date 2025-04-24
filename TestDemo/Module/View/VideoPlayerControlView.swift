//
//  VideoPlayerControlView.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/24.
//
import UIKit
import AVFoundation

protocol VideoPlayerControlViewDelegate: AnyObject {
    func controlViewDidTapPlayPause(_ controlView: VideoPlayerControlView)
    func controlViewDidTapFullscreen(_ controlView: VideoPlayerControlView)
    func controlView(_ controlView: VideoPlayerControlView, didSelectQuality quality: VideoQuality)
    func controlView(_ controlView: VideoPlayerControlView, isSeekingTo time: TimeInterval)
    func controlView(_ controlView: VideoPlayerControlView, didSeekTo time: TimeInterval)
    func controlViewDidTapBackward(_ controlView: VideoPlayerControlView)
    func controlViewDidTapForward(_ controlView: VideoPlayerControlView)
}

struct VideoQuality {
    let title: String
    let url: URL
}

class VideoPlayerControlView: UIView {
    
    // MARK: - Properties
    weak var delegate: VideoPlayerControlViewDelegate?
    
    var isPlaying: Bool = false {
        didSet {
            playPauseButton.setImage(isPlaying ? pauseImage : playImage, for: .normal)
        }
    }
    
    var isSliding = false // 标记是否正在拖动进度条
    
    private var isFullscreen: Bool = false {
        didSet {
            fullscreenButton.setImage(isFullscreen ? exitFullscreenImage : fullscreenImage, for: .normal)
        }
    }
    
    private var currentTime: TimeInterval = 0 {
        didSet {
            updateTimeLabels()
        }
    }
    
    private var duration: TimeInterval = 0 {
        didSet {
            updateTimeLabels()
        }
    }
    
    private var bufferedTime: TimeInterval = 0 {
        didSet {
            updateProgressViews()
        }
    }
    
    // UI Elements
    private let playPauseButton = UIButton()
    private let fullscreenButton = UIButton()
    private let backwardButton = UIButton()
    private let forwardButton = UIButton()
    private let qualityButton = UIButton()
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let progressSlider = UISlider()
    private let bufferedProgressView = UIProgressView()
    private let panGesture = UIPanGestureRecognizer()
    
    // Images
    private let playImage = UIImage(systemName: "play.fill")
    private let pauseImage = UIImage(systemName: "pause.fill")
    private let fullscreenImage = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
    private let exitFullscreenImage = UIImage(systemName: "arrow.down.right.and.arrow.up.left")
    private let backwardImage = UIImage(systemName: "gobackward.10")
    private let forwardImage = UIImage(systemName: "goforward.10")
    private let qualityImage = UIImage(systemName: "list.dash")
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupGestures()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Stack View for top controls
        let topStackView = UIStackView()
        topStackView.axis = .horizontal
        topStackView.distribution = .fill
        topStackView.alignment = .center
        topStackView.spacing = 16
        
        // Stack View for bottom controls
        let bottomStackView = UIStackView()
        bottomStackView.axis = .horizontal
        bottomStackView.distribution = .fill
        bottomStackView.alignment = .center
        bottomStackView.spacing = 16
        
        // Configure buttons
        playPauseButton.setImage(pauseImage, for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        
        fullscreenButton.setImage(fullscreenImage, for: .normal)
        fullscreenButton.tintColor = .white
        fullscreenButton.addTarget(self, action: #selector(fullscreenTapped), for: .touchUpInside)
        
        backwardButton.setImage(backwardImage, for: .normal)
        backwardButton.tintColor = .white
        backwardButton.addTarget(self, action: #selector(backwardTapped), for: .touchUpInside)
        
        forwardButton.setImage(forwardImage, for: .normal)
        forwardButton.tintColor = .white
        forwardButton.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)
        
        qualityButton.setImage(qualityImage, for: .normal)
        qualityButton.tintColor = .white
        qualityButton.addTarget(self, action: #selector(qualityTapped), for: .touchUpInside)
        
        // Configure labels
        currentTimeLabel.text = "00:00"
        currentTimeLabel.textColor = .white
        currentTimeLabel.font = .systemFont(ofSize: 12)
        
        durationLabel.text = "00:00"
        durationLabel.textColor = .white
        durationLabel.font = .systemFont(ofSize: 12)
        
        // Configure progress views
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1.0
        progressSlider.minimumTrackTintColor = .systemBlue
        progressSlider.maximumTrackTintColor = .clear
        progressSlider.setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
        progressSlider.tintColor = .white
        progressSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderTouchUpInside(_:)), for: [.touchUpInside, .touchUpOutside])
        
        bufferedProgressView.progressTintColor = UIColor.white.withAlphaComponent(0.5)
        bufferedProgressView.trackTintColor = UIColor.lightGray.withAlphaComponent(0.3)
        
        // Add to stack views
        topStackView.addArrangedSubview(qualityButton)
        topStackView.addArrangedSubview(UIView()) // Spacer
        
        bottomStackView.addArrangedSubview(backwardButton)
        bottomStackView.addArrangedSubview(playPauseButton)
        bottomStackView.addArrangedSubview(forwardButton)
        bottomStackView.addArrangedSubview(currentTimeLabel)
        bottomStackView.addArrangedSubview(progressSlider)
        bottomStackView.addArrangedSubview(durationLabel)
        bottomStackView.addArrangedSubview(fullscreenButton)
        
        // Add to view
        addSubview(topStackView)
        addSubview(bottomStackView)
        addSubview(bufferedProgressView)
        
        // Layout
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        bufferedProgressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            topStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            topStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            bottomStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            bottomStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bottomStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            bufferedProgressView.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
            bufferedProgressView.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor),
            bufferedProgressView.centerYAnchor.constraint(equalTo: progressSlider.centerYAnchor),
            bufferedProgressView.heightAnchor.constraint(equalToConstant: 2),
            
            qualityButton.widthAnchor.constraint(equalToConstant: 24),
            qualityButton.heightAnchor.constraint(equalToConstant: 24),
            
            playPauseButton.widthAnchor.constraint(equalToConstant: 24),
            playPauseButton.heightAnchor.constraint(equalToConstant: 24),
            
            backwardButton.widthAnchor.constraint(equalToConstant: 24),
            backwardButton.heightAnchor.constraint(equalToConstant: 24),
            
            forwardButton.widthAnchor.constraint(equalToConstant: 24),
            forwardButton.heightAnchor.constraint(equalToConstant: 24),
            
            fullscreenButton.widthAnchor.constraint(equalToConstant: 24),
            fullscreenButton.heightAnchor.constraint(equalToConstant: 24),
            
            progressSlider.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Bring slider to front
        bringSubviewToFront(progressSlider)
    }
    
    private func setupGestures() {
        
        // 双击手势（用于播放/暂停）
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
        
        // 滑动手势
        panGesture.addTarget(self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }


    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        delegate?.controlViewDidTapPlayPause(self)
    }
    
    // MARK: - Public Methods
    func updatePlaybackStatus(isPlaying: Bool) {
        self.isPlaying = isPlaying
    }
    
    func updateFullscreenStatus(isFullscreen: Bool) {
        self.isFullscreen = isFullscreen
    }
    
    func updateTime(currentTime: TimeInterval, duration: TimeInterval) {
        self.currentTime = currentTime
        self.duration = duration
        progressSlider.value = Float(currentTime / duration)
    }
    
    func updateBufferedTime(bufferedTime: TimeInterval) {
        self.bufferedTime = bufferedTime
    }
    
    // MARK: - Private Methods
    private func updateTimeLabels() {
        currentTimeLabel.text = formatTime(seconds: currentTime)
        durationLabel.text = formatTime(seconds: duration)
    }
    
    private func updateProgressViews() {
        let bufferedProgress = Float(bufferedTime / duration)
        bufferedProgressView.setProgress(bufferedProgress, animated: true)
    }
    
    private func formatTime(seconds: TimeInterval) -> String {
        guard !seconds.isNaN else { return "00:00" }
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Actions
    @objc private func playPauseTapped() {
        delegate?.controlViewDidTapPlayPause(self)
    }
    
    @objc private func fullscreenTapped() {
        delegate?.controlViewDidTapFullscreen(self)
    }
    
    @objc private func backwardTapped() {
        delegate?.controlViewDidTapBackward(self)
    }
    
    @objc private func forwardTapped() {
        delegate?.controlViewDidTapForward(self)
    }
    
    @objc private func qualityTapped() {
        // In a real implementation, you would show a quality selection menu
        // For simplicity, we'll just notify the delegate
        let quality = VideoQuality(title: "720p", url: URL(string: "https://example.com")!)
        delegate?.controlView(self, didSelectQuality: quality)
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        print("sliderValueChanged slider.value = \(slider.value)")
        isSliding = true
        let seekTime = TimeInterval(slider.value) * duration
        currentTimeLabel.text = formatTime(seconds: seekTime)
        delegate?.controlView(self, isSeekingTo: seekTime)
    }
    
    @objc private func sliderTouchUpInside(_ slider: UISlider) {
        print("sliderTouchUpInside  slider.value = \(slider.value)")
        isSliding = false
        let seekTime = TimeInterval(slider.value) * duration
        delegate?.controlView(self, didSeekTo: seekTime)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        // Implement brightness/volume/slider control based on pan direction
        // This is a simplified version - you can expand it
        let translation = gesture.translation(in: self)
        
        if abs(translation.x) > abs(translation.y) {
            // Horizontal pan - seek
            let progress = Float(translation.x / bounds.width)
            let newValue = progressSlider.value + progress
            progressSlider.value = min(max(newValue, 0), 1)
            sliderValueChanged(progressSlider)
            
            if gesture.state == .ended {
                sliderTouchUpInside(progressSlider)
            }
        }
    }
}
