//
//  InviteFriendsPosterViewController.swift
//  HYPrinter
//

import CoreImage
import Photos
import UIKit

/// 从底部弹起的邀请页（约屏幕 2/3 高），海报仅含背景图与二维码。
final class InviteFriendsPosterViewController: UIViewController {

    private let posterImage: UIImage

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return v
    }()

    private let panel: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#F6F8FC") ?? .systemGroupedBackground
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        return v
    }()

    private let grabber: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#D0D5DD")
        v.layer.cornerRadius = 2.5
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "邀请好友"
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = UIColor(hexString: "#1D212C")
        l.textAlignment = .center
        return l
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        let img = UIImage(systemName: "xmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium))?
            .withTintColor(UIColor(hexString: "#9AA4B2") ?? .gray, renderingMode: .alwaysOriginal)
        b.setImage(img, for: .normal)
        b.accessibilityLabel = "关闭"
        return b
    }()

    private let posterView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        return iv
    }()

    private let buttonStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 12
        s.distribution = .fillEqually
        return s
    }()

    private lazy var shareButton: UIButton = makePrimaryButton(title: "分享给好友", action: #selector(onShare))
    private lazy var saveButton: UIButton = makeSecondaryButton(title: "保存到相册", action: #selector(onSaveToAlbum))

    private var didPlayEntranceAnimation = false

    init(posterImage: UIImage) {
        self.posterImage = posterImage
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        dimView.alpha = 0
        posterView.image = posterImage

        view.addSubview(dimView)
        view.addSubview(panel)
        panel.addSubview(grabber)
        panel.addSubview(titleLabel)
        panel.addSubview(closeButton)
        panel.addSubview(posterView)
        panel.addSubview(buttonStack)
        buttonStack.addArrangedSubview(shareButton)
        buttonStack.addArrangedSubview(saveButton)

        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(kScreenHeight - kTabbarHeight)
        }

        grabber.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(36)
            make.height.equalTo(5)
        }
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().inset(12)
            make.width.height.equalTo(36)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(48)
            make.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-8)
        }
        posterView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(buttonStack.snp.top).offset(-16)
        }
        buttonStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(panel.safeAreaLayoutGuide.snp.bottom).offset(-12)
        }
        [shareButton, saveButton].forEach { $0.snp.makeConstraints { $0.height.equalTo(50) } }

        let tap = UITapGestureRecognizer(target: self, action: #selector(onDimTap))
        dimView.addGestureRecognizer(tap)
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !didPlayEntranceAnimation {
            let h = view.bounds.height * (2.0 / 3.0)
            panel.transform = CGAffineTransform(translationX: 0, y: h)
            dimView.alpha = 0
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didPlayEntranceAnimation else { return }
        didPlayEntranceAnimation = true
        UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0.6, options: [.curveEaseOut]) {
            self.panel.transform = .identity
            self.dimView.alpha = 1
        }
    }

    @objc private func onDimTap() {
        dismissPanel()
    }

    @objc private func onClose() {
        dismissPanel()
    }

    private func dismissPanel() {
        let h = view.bounds.height * (2.0 / 3.0)
        UIView.animate(withDuration: 0.26, delay: 0, options: [.curveEaseIn]) {
            self.panel.transform = CGAffineTransform(translationX: 0, y: h)
            self.dimView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }

    private func makePrimaryButton(title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = kmainColor
        b.layer.cornerRadius = 12
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    private func makeSecondaryButton(title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(kmainColor, for: .normal)
        b.backgroundColor = .white
        b.layer.cornerRadius = 12
        b.layer.borderWidth = 1
        b.layer.borderColor = kmainColor.cgColor
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    @objc private func onShare() {
        let vc = UIActivityViewController(activityItems: [posterImage], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = shareButton
        present(vc, animated: true)
    }

    @objc private func onSaveToAlbum() {
        let save = { [weak self] in
            guard let self else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: self.posterImage)
            }, completionHandler: { ok, err in
                DispatchQueue.main.async {
                    if ok {
                        self.showToast("已保存到相册")
                    } else {
                        self.showToast(err?.localizedDescription ?? "保存失败")
                    }
                }
            })
        }

        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            save()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { new in
                DispatchQueue.main.async {
                    if new == .authorized || new == .limited {
                        save()
                    } else {
                        self.showToast("请在设置中允许访问相册以保存海报")
                    }
                }
            }
        default:
            showToast("请在设置中允许「添加照片」以保存海报")
        }
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - 海报：仅背景图 + 二维码

enum InvitePosterBuilder {

    /// 二维码中心相对画布的位置（0~1），可按设计微调。
    private static let qrCenterXRatio: CGFloat = 0.5
    private static let qrCenterYRatio: CGFloat = 0.68
    /// 二维码边长占画布宽度比例。
    private static let qrWidthRatio: CGFloat = 0.36

    /// 在 `Info.plist` 中配置 `InviteDownloadURL` 为 App 下载页或 App Store 链接。
    static func inviteDownloadURLString() -> String {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "InviteDownloadURL") as? String {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
        }
        return "https://apps.apple.com"
    }

    /// 输出与背景图同像素尺寸（按资源 @1x/@2x/@3x），便于分享与保存。
    static func makePosterImage() -> UIImage {
        let bgName = "invite_friend_ic"
        guard let bg = UIImage(named: bgName) else {
            return makeFallbackPoster()
        }

        let canvasSize = CGSize(width: bg.size.width * bg.scale, height: bg.size.height * bg.scale)
        let urlString = inviteDownloadURLString()
        let qrPixel = canvasSize.width * qrWidthRatio
        let qr = makeQRCodeImage(from: urlString, pixelWidth: qrPixel) ?? UIImage()

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        return renderer.image { _ in
            bg.draw(in: CGRect(origin: .zero, size: canvasSize))
            let side = canvasSize.width * qrWidthRatio
            let center = CGPoint(x: canvasSize.width * qrCenterXRatio, y: canvasSize.height * qrCenterYRatio)
            let qrRect = CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side)
            qr.draw(in: qrRect)
        }
    }

    private static func makeFallbackPoster() -> UIImage {
        let size = CGSize(width: 1080, height: 1620)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor(hexString: "#EEF1F7")?.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    private static func makeQRCodeImage(from string: String, pixelWidth: CGFloat) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter?.outputImage else { return nil }
        let scale = pixelWidth / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
