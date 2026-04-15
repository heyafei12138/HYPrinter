//
//  HomeCheckInFloatingView.swift
//  HYPrinter
//

import UIKit

/// 首页可拖动悬浮签到：半透明圆图背景 + 外圈倒计时进度，结束后显示「签到」；松手吸附最近屏幕边。
final class HomeCheckInFloatingView: UIView {

    static let diameter: CGFloat = 64
    private static let ringLineWidth: CGFloat = 3.5
    private let totalSeconds = 60

    var onTapWhenUnlocked: (() -> Void)?

    private var remainingSeconds = 60
    private var timer: Timer?
    private var isUnlocked = false

    private let ringHost = UIView()
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
//        iv.alpha = 0.88
        iv.image = UIImage(named: "revord_icon") ?? UIImage(named: "AppIconImage")
        return iv
    }()

    private let dimOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        return v
    }()

    private let centerLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = UIColor(hexString: "#1D212C")?.withAlphaComponent(0.8)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.5
        return l
    }()

    private var panStartCenter: CGPoint = .zero

    override init(frame: CGRect) {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: Self.diameter, height: Self.diameter)))
        backgroundColor = .clear
        clipsToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.38
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 8

        addSubview(ringHost)
        ringHost.layer.addSublayer(trackLayer)
        ringHost.layer.addSublayer(progressLayer)

        addSubview(backgroundImageView)
        addSubview(dimOverlay)
        addSubview(centerLabel)

        ringHost.backgroundColor = .clear
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor(hexString: "#E0E4EB")?.cgColor ?? UIColor.systemGray4.cgColor
        trackLayer.lineWidth = Self.ringLineWidth
        trackLayer.lineCap = .round

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.red.withAlphaComponent(0.5).cgColor
        progressLayer.lineWidth = Self.ringLineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = 0

        backgroundImageView.layer.cornerRadius = (Self.diameter - Self.ringLineWidth * 2) / 2
        backgroundImageView.layer.masksToBounds = true
        dimOverlay.layer.cornerRadius = backgroundImageView.layer.cornerRadius
        dimOverlay.layer.masksToBounds = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)

        ringHost.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let innerInset = Self.ringLineWidth + 1.5
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: innerInset, left: innerInset, bottom: innerInset, right: innerInset))
        }
        dimOverlay.snp.makeConstraints { make in
            make.edges.equalTo(backgroundImageView)
        }
        centerLabel.snp.makeConstraints { make in
            make.center.equalTo(backgroundImageView)
            make.leading.trailing.equalTo(backgroundImageView).inset(4)
        }

        updateProgressRing()
        updateCenterText()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.diameter, height: Self.diameter)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let lw = Self.ringLineWidth
        let r = (min(bounds.width, bounds.height) - lw) / 2
        let c = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(
            arcCenter: c,
            radius: r,
            startAngle: -.pi / 2,
            endAngle: .pi * 3 / 2,
            clockwise: true
        )
        trackLayer.frame = bounds
        progressLayer.frame = bounds
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
        trackLayer.strokeEnd = 1
        updateProgressRing()
        layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
    }

    deinit {
        stopTimer()
    }

    func resumeOrStartIfNeeded() {
        guard !isUnlocked else { return }
        if timer == nil {
            startTimer()
        }
    }

    func pauseTimer() {
        stopTimer()
    }

    /// 手动签到完成后：从 60 秒重新开始圆环倒计时，期间不可点「签到」。
    func restartCountdownAfterSignIn() {
        isUnlocked = false
        remainingSeconds = totalSeconds
        stopTimer()
        updateProgressRing()
        updateCenterText()
        startTimer()
    }

    private func startTimer() {
        stopTimer()
        let t = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard !isUnlocked else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        if remainingSeconds <= 0 {
            isUnlocked = true
            stopTimer()
            PointsManager.shared.markHomeFloatingCheckInUnlocked()
        }
        updateProgressRing()
        updateCenterText()
    }

    private func updateProgressRing() {
        let done = CGFloat(totalSeconds - remainingSeconds) / CGFloat(totalSeconds)
        progressLayer.strokeEnd = min(1, max(0, done))
    }

    private func updateCenterText() {
        if isUnlocked {
            centerLabel.text = "签到"
            centerLabel.textColor = UIColor(hexString: "#1D212C")
        } else {
            centerLabel.text = "\(remainingSeconds)"
            centerLabel.textColor = UIColor(hexString: "#1D212C")!.withAlphaComponent(0.8)
        }
    }

    @objc private func handleTap() {
        guard isUnlocked else { return }
        onTapWhenUnlocked?()
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard let sv = superview else { return }
        let translation = g.translation(in: sv)
        switch g.state {
        case .began:
            panStartCenter = center
        case .changed:
            var next = CGPoint(x: panStartCenter.x + translation.x, y: panStartCenter.y + translation.y)
            next = clampCenter(next, in: sv)
            center = next
        case .ended, .cancelled:
            var next = CGPoint(x: panStartCenter.x + translation.x, y: panStartCenter.y + translation.y)
            next = clampCenter(next, in: sv)
            center = next
            snapToNearestEdge(in: sv)
        default:
            break
        }
    }

    private func clampCenter(_ p: CGPoint, in sv: UIView) -> CGPoint {
        let safe = sv.safeAreaInsets
        let b = sv.bounds
        let halfW = bounds.width / 2
        let halfH = bounds.height / 2
        let m: CGFloat = 4
        let minX = halfW + m
        let maxX = b.width - halfW - m
        let minY = halfH + m + safe.top
        let maxY = b.height - halfH - m - safe.bottom
        return CGPoint(
            x: min(max(p.x, minX), maxX),
            y: min(max(p.y, minY), maxY)
        )
    }

    /// 吸附到离当前中心最近的屏幕边（左/右/上/下之一）。
    private func snapToNearestEdge(in sv: UIView) {
        let safe = sv.safeAreaInsets
        let b = sv.bounds
        let halfW = bounds.width / 2
        let halfH = bounds.height / 2
        let m: CGFloat = 6
        let minX = halfW + m
        let maxX = b.width - halfW - m
        let minY = halfH + m + safe.top
        let maxY = b.height - halfH - m - safe.bottom

        var x = center.x
        var y = center.y
        let dLeft = x - minX
        let dRight = maxX - x
        let dTop = y - minY
        let dBottom = maxY - y
        let minH = min(dLeft, dRight)
        let minV = min(dTop, dBottom)
        if minH <= minV {
            x = dLeft <= dRight ? minX : maxX
            y = min(max(y, minY), maxY)
        } else {
            y = dTop <= dBottom ? minY : maxY
            x = min(max(x, minX), maxX)
        }
        UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.86, initialSpringVelocity: 0.45) {
            self.center = CGPoint(x: x, y: y)
        }
    }
}
