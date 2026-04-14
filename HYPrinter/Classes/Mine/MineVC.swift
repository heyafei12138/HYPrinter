//
//  MineVC.swift
//  HYPrinter
//

import MessageUI
import SafariServices
import StoreKit
import UIKit

final class MineVC: BaseViewController {

    override var shouldHideNavigationBar: Bool {
        get { true }
        set { }
    }

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerContainer = UIView()
    private let headerBackgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = UIImage(named: "minebanner_ic")
        return iv
    }()

    private let headerBlurOverlay: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let v = UIVisualEffectView(effect: blur)
        v.alpha = 0.35
        return v
    }()

    private let headerGradientOverlay = MineBottomGradientOverlay()

    

    private let avatarContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 40
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        v.layer.masksToBounds = true
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 36
        iv.layer.masksToBounds = true
        iv.image = UIImage(named: "AppIconImage") ?? UIImage(systemName: "person.crop.circle.fill")
        iv.tintColor = UIColor(hexString: "#C5CCD6")
        return iv
    }()

    private let nicknameLabel: UILabel = {
        let l = UILabel()
        l.text = "掌上打印用户9834"
        l.font = .systemFont(ofSize: 23, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let signatureLabel: UILabel = {
        let l = UILabel()
        l.text = "普通会员 · 点击完善资料"
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.88)
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    private let cardsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        s.alignment = .fill
        return s
    }()

    private let listCard = UIView()
    private let listStack = UIStackView()
    private let versionFootnoteLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = UIColor(hexString: "#B0B8C4")
        l.textAlignment = .center
        l.numberOfLines = 1
        return l
    }()

    override func buildSubviews() {
        super.buildSubviews()
        view.backgroundColor = UIColor(hexString: "#EEF1F7") ?? kBgColor

        view.addSubview(scrollView)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.addSubview(contentView)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        contentView.addSubview(headerContainer)
        headerContainer.addSubview(headerBackgroundImageView)
        headerContainer.addSubview(headerBlurOverlay)
        headerContainer.addSubview(headerGradientOverlay)
        headerContainer.addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        headerContainer.addSubview(nicknameLabel)
        headerContainer.addSubview(signatureLabel)


        contentView.addSubview(cardsStack)
        contentView.addSubview(listCard)
        listCard.addSubview(listStack)
        contentView.addSubview(versionFootnoteLabel)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        let headerHeight: CGFloat = 348
        headerContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(headerHeight)
        }
        headerBackgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        headerBlurOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        headerGradientOverlay.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(120)
        }


        avatarContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(18)
            make.width.height.equalTo(80)
        }
        avatarImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(76)
        }

        nicknameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarContainer.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(24)
        }
//        signatureLabel.snp.makeConstraints { make in
//            make.top.equalTo(nicknameLabel.snp.bottom).offset(6)
//            make.leading.trailing.equalToSuperview().inset(24)
//            make.bottom.lessThanOrEqualToSuperview().inset(20)
//        }

        cardsStack.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom).offset(-28)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        let rewardsCard = MineFeatureCardView(
            symbolName: "mine_gift",
            title: "我的奖励",
            subtitle: "积分多多"
        )
        let inviteCard = MineFeatureCardView(
            symbolName: "mine_invite",
            title: "我的邀请",
            subtitle: "好友共享"
        )
        let supportCard = MineFeatureCardView(
            symbolName: "mine_server",
            title: "客服",
            subtitle: "获取帮助"
        )
        cardsStack.addArrangedSubview(rewardsCard)
        cardsStack.addArrangedSubview(inviteCard)
        cardsStack.addArrangedSubview(supportCard)
        [rewardsCard, inviteCard, supportCard].forEach { $0.snp.makeConstraints { $0.height.equalTo(110) } }

        listCard.backgroundColor = .white
        listCard.layer.cornerRadius = 20
        listCard.layer.masksToBounds = false
        listCard.layer.shadowColor = UIColor.black.cgColor
        listCard.layer.shadowOpacity = 0.06
        listCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        listCard.layer.shadowRadius = 12

        listStack.axis = .vertical
        listStack.spacing = 0

        listCard.snp.makeConstraints { make in
            make.top.equalTo(cardsStack.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        listStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0))
        }

        buildListRows()

        versionFootnoteLabel.text = MineVC.appVersionFootnoteString()
        versionFootnoteLabel.snp.makeConstraints { make in
            make.top.equalTo(listCard.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(28 + kTabbarHeight)
        }

        rewardsCard.onTap = { [weak self] in self?.showPlaceholderToast("我的奖励") }
        inviteCard.onTap = { [weak self] in self?.showPlaceholderToast("我的邀请") }
        supportCard.onTap = { [weak self] in self?.openSupport() }
    }

    private func buildListRows() {
        let rows: [(icon: String, title: String, showsArrow: Bool, detail: String?, action: () -> Void)] = [
            ("lock.shield.fill", "隐私政策", true, nil, { [weak self] in self?.openPrivacy() }),
            ("info.circle.fill", "关于我们", true, nil, { [weak self] in self?.showAbout() }),
            ("envelope.fill", "邮件反馈", true, nil, { [weak self] in self?.openEmailFeedback() }),
            ("star.fill", "给个好评", true, nil, { [weak self] in self?.requestReview() })
        ]

        for (index, row) in rows.enumerated() {
            let tap = MineListRowView(
                symbolName: row.icon,
                title: row.title,
                showsArrow: row.showsArrow,
                detailText: row.detail
            )
            tap.onTap = row.action
            listStack.addArrangedSubview(tap)
            tap.snp.makeConstraints { make in
                make.height.equalTo(52)
            }
            if index < rows.count - 1 {
                let line = UIView()
                line.backgroundColor = UIColor(hexString: "#ECEFF3")
                listStack.addArrangedSubview(line)
                line.snp.makeConstraints { make in
                    make.height.equalTo(1 / UIScreen.main.scale)
                }
            }
        }
    }

    private static func shortVersionString() -> String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? short : "\(short) (\(build))"
    }

    private static func appVersionFootnoteString() -> String {
        let info = Bundle.main.infoDictionary
        let name = info?["CFBundleDisplayName"] as? String ?? info?["CFBundleName"] as? String ?? "HYPrinter"
        let ver = shortVersionString()
        return "\(name) \(ver)"
    }

    @objc private func onSettingsTap() {
        showPlaceholderToast("设置")
    }

    private func showPlaceholderToast(_ name: String) {
        let alert = UIAlertController(title: nil, message: "\(name) 功能即将上线", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }

    private func openPrivacy() {
        let url = URL(string: "https://www.apple.com/legal/privacy/")!
        let vc = SFSafariViewController(url: url)
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }

    private func showAbout() {
        let msg = "\(MineVC.appVersionFootnoteString())\n\n一款便捷的移动打印应用。"
        let alert = UIAlertController(title: "关于我们", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }

    private func requestReview() {
        let scene = view.window?.windowScene
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        if let scene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func openSupport() {
        let alert = UIAlertController(title: "客服中心", message: "如需帮助，请通过 App 内反馈或邮件联系我们。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }

    /// 可在 `Info.plist` 中配置 `FeedbackEmail`（收件人）；未配置时收件人为空，由用户自行填写。
    private static func feedbackRecipientEmail() -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "FeedbackEmail") as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func openEmailFeedback() {
        let subject = "HYPrinter 意见反馈"
        let body = "请描述您遇到的问题或建议：\n\n\n——\n\(MineVC.appVersionFootnoteString())"

        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)
            if let to = MineVC.feedbackRecipientEmail() {
                mail.setToRecipients([to])
            }
            present(mail, animated: true)
            return
        }

        var components = URLComponents()
        components.scheme = "mailto"
        if let to = MineVC.feedbackRecipientEmail() {
            components.path = to
        }
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        guard let url = components.url else {
            let alert = UIAlertController(title: nil, message: "无法打开邮件，请检查是否已配置系统邮箱。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好的", style: .default))
            present(alert, animated: true)
            return
        }
        UIApplication.shared.open(url, options: [:]) { [weak self] ok in
            guard let self else { return }
            if !ok {
                let alert = UIAlertController(title: nil, message: "无法打开邮件应用。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "好的", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
}

extension MineVC: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

// MARK: - 顶部渐变遮罩

private final class MineBottomGradientOverlay: UIView {
    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradient.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.55).cgColor
        ]
        gradient.locations = [0.25, 1.0]
        layer.addSublayer(gradient)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}

// MARK: - 功能卡片

private final class MineFeatureCardView: UIView {
    var onTap: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    init(symbolName: String, title: String, subtitle: String) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 10

        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iconView.image = UIImage(named: symbolName)
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(hexString: "#1D212C")

        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 10, weight: .regular)
        subtitleLabel.textColor = UIColor(hexString: "#78818D")?.withAlphaComponent(0.7)
        subtitleLabel.numberOfLines = 2

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(36)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.lessThanOrEqualToSuperview().inset(12)

        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        onTap?()
    }
}

// MARK: - 列表行

private final class MineListRowView: UIView {
    var onTap: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let arrowView = UIImageView()

    init(symbolName: String, title: String, showsArrow: Bool, detailText: String?) {
        super.init(frame: .zero)
        isUserInteractionEnabled = true

        let icfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconView.image = UIImage(systemName: symbolName, withConfiguration: icfg)?
            .withTintColor(UIColor(hexString: "#5B6472") ?? .gray, renderingMode: .alwaysOriginal)
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1D212C")

        detailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        detailLabel.textColor = UIColor(hexString: "#9AA4B2")
        detailLabel.text = detailText
        detailLabel.textAlignment = .right

        if showsArrow {
            arrowView.image = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))?
                .withTintColor(UIColor(hexString: "#C5CCD6") ?? .lightGray, renderingMode: .alwaysOriginal)
        }
        arrowView.isHidden = !showsArrow

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(arrowView)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.width.equalTo(10)
            make.height.equalTo(16)
        }
        if showsArrow {
            detailLabel.snp.makeConstraints { make in
                make.trailing.equalTo(arrowView.snp.leading).offset(-6)
                make.centerY.equalToSuperview()
                make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
            }
        } else {
            detailLabel.snp.makeConstraints { make in
                make.trailing.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
            }
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        onTap?()
    }
}
