//
//  SignInViewController.swift
//  HYPrinter
//

import UIKit

/// 每日签到：需首页悬浮倒计时结束后才可点击；每次 +20 积分。
final class SignInViewController: BaseViewController {

    override var shouldHideNavigationBar: Bool {
        get { false }
        set { }
    }

    private let balanceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = UIColor(hexString: "#1D212C")
        l.textAlignment = .center
        return l
    }()

    private let lockHintLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor(hexString: "#E53935") ?? .systemRed
        l.textAlignment = .center
        l.numberOfLines = 0
        l.text = "请先在首页等待右上角悬浮签到的圆环倒计时结束（显示「签到」）后，再返回本页点击签到。"
        return l
    }()

    private let signButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("签到领积分", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = kmainColor
        b.layer.cornerRadius = 14
        return b
    }()

    private let contentMidGuide = UILayoutGuide()

    private let activityIntroLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(hexString: "#5B6472")
        l.textAlignment = .left
        l.numberOfLines = 0
        l.text = """
        【当前活动说明】
        · 每日首次打开 App 将自动获得 \(PointsManager.dailyAutoCheckInPoints) 积分（以弹窗提示为准）。
        · 完成首页悬浮签到倒计时后，每点击一次「签到领积分」可获得 \(PointsManager.manualCheckInPoints) 积分。
        · 每次打印将消耗 \(PointsManager.printCost) 积分，请保持积分充足。
        """
        return l
    }()

    override func buildSubviews() {
        super.buildSubviews()
        title = "每日签到"
        allowsInteractivePop = true
        view.backgroundColor = UIColor(hexString: "#EEF1F7") ?? kBgColor

        view.addLayoutGuide(contentMidGuide)
        view.addSubview(balanceLabel)
        view.addSubview(lockHintLabel)
        view.addSubview(signButton)
        view.addSubview(activityIntroLabel)

        contentMidGuide.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(48)
            make.leading.trailing.equalToSuperview()
        }

        balanceLabel.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        lockHintLabel.snp.makeConstraints { make in
            make.top.equalTo(balanceLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(22)
        }
        signButton.snp.makeConstraints { make in
            make.top.equalTo(lockHintLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(40)
            make.height.equalTo(52)
            make.bottom.lessThanOrEqualTo(contentMidGuide.snp.top).offset(-12)
        }
        activityIntroLabel.snp.makeConstraints { make in
            make.top.equalTo(contentMidGuide.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
        }

        signButton.addTarget(self, action: #selector(onSignTap), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUI), name: .pointsBalanceDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUI), name: .homeFloatingCheckInUnlocked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUI), name: .homeFloatingCheckInShouldRestart, object: nil)
        refreshUI()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func refreshUI() {
        let pts = PointsManager.shared.balance
        balanceLabel.text = "当前积分：\(pts)"
        let unlocked = PointsManager.shared.isHomeFloatingCheckInUnlocked
        lockHintLabel.isHidden = unlocked
        signButton.isEnabled = unlocked
        signButton.alpha = unlocked ? 1 : 0.42
    }

    @objc private func onSignTap() {
        guard PointsManager.shared.isHomeFloatingCheckInUnlocked else { return }
        let result = PointsManager.shared.performManualSignIn()
        let alert = UIAlertController(title: result.ok ? "成功" : "提示", message: result.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
        refreshUI()
    }
}
