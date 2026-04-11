//
//  LaunchTransitionVC.swift
//  HYPrinter
//
//  Created by Codex on 2026/4/10.
//

import UIKit
import AVFoundation

final class LaunchTransitionVC: UIViewController {
    
    var onFinish: (() -> Void)?
    
    private let videoContainerView = UIView()
    private let previewImageView = UIImageView()
    private let topLeftMaskView = UIView()
    private let topLeftMaskView1 = UIView()

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerReadyObservation: NSKeyValueObservation?
    private var finishWorkItem: DispatchWorkItem?
    private var playbackObserver: NSObjectProtocol?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildSubviews()
        configurePlayer()
        scheduleFinish()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
    }
    
    deinit {
        if let playbackObserver {
            NotificationCenter.default.removeObserver(playbackObserver)
        }
        playerReadyObservation?.invalidate()
        finishWorkItem?.cancel()
    }
}

// MARK: - Build UI
extension LaunchTransitionVC {
    
    private func buildSubviews() {
        view.backgroundColor = .white
        
        videoContainerView.backgroundColor = kBgColor
        view.addSubview(videoContainerView)
        videoContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        videoContainerView.addSubview(previewImageView)
        previewImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        topLeftMaskView.backgroundColor = kBgColor
        view.addSubview(topLeftMaskView)
        topLeftMaskView.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.width.equalTo(148)
            make.height.equalTo(96 + kStatusBarHeight)
        }
        
        topLeftMaskView1.backgroundColor = kBgColor
        view.addSubview(topLeftMaskView1)
        topLeftMaskView1.snp.makeConstraints { make in
            make.bottom.right.equalToSuperview()
            make.width.equalTo(148)
            make.height.equalTo(96)
        }
    }
}

// MARK: - Player
extension LaunchTransitionVC {
    
    private func configurePlayer() {
        guard let videoURL = Bundle.main.url(forResource: "lanchvideo", withExtension: "mp4") else {
            return
        }
        
        previewImageView.image = makePreviewImage(from: videoURL)
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let player = AVPlayer(url: videoURL)
        player.isMuted = false
        player.volume = 1
        self.player = player
        
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.backgroundColor = UIColor.clear.cgColor
        videoContainerView.layer.addSublayer(layer)
        self.playerLayer = layer
        
        playerReadyObservation = layer.observe(\.isReadyForDisplay, options: [.new]) { [weak self] _, change in
            guard change.newValue == true else { return }
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.18, animations: {
                    self?.previewImageView.alpha = 0
                }, completion: { _ in
                    self?.previewImageView.isHidden = true
                })
            }
        }
        
        playbackObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        
        player.play()
    }
    
    private func makePreviewImage(from videoURL: URL) -> UIImage? {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: UIScreen.main.bounds.width * 2,
                                            height: UIScreen.main.bounds.height * 2)
        
        let captureTime = CMTime(seconds: 0.05, preferredTimescale: 600)
        guard let imageRef = try? imageGenerator.copyCGImage(at: captureTime, actualTime: nil) else {
            return nil
        }
        return UIImage(cgImage: imageRef)
    }
}

// MARK: - Flow
extension LaunchTransitionVC {
    
    private func scheduleFinish() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.finishTransition()
        }
        finishWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }
    
    private func finishTransition() {
        player?.pause()
        onFinish?()
    }
}
