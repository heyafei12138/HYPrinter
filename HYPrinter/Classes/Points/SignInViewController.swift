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
        l.text = "Please wait until the floating check-in countdown on Home finishes (shows “Check in”), then return here to check in."
        return l
    }()

    private let signButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Check in for points", for: .normal)
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
        [Current Activity Rules]
        · On the first app launch each day, you automatically get \(PointsManager.dailyAutoCheckInPoints) points (subject to popup notice).
        · After the floating check-in countdown on Home is finished, each tap on “Check in for points” gives \(PointsManager.manualCheckInPoints) points.
        · Each print consumes \(PointsManager.printCost) points. Please keep enough points available.
        """
        return l
    }()

    override func buildSubviews() {
        super.buildSubviews()
        title = "Daily Check-in"
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
        balanceLabel.text = "Current points: \(pts)"
        let unlocked = PointsManager.shared.isHomeFloatingCheckInUnlocked
        lockHintLabel.isHidden = unlocked
        signButton.isEnabled = unlocked
        signButton.alpha = unlocked ? 1 : 0.42
    }

    @objc private func onSignTap() {
        guard PointsManager.shared.isHomeFloatingCheckInUnlocked else { return }
        let result = PointsManager.shared.performManualSignIn()
        let alert = UIAlertController(title: result.ok ? "Success" : "Notice", message: result.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        refreshUI()
    }
}
