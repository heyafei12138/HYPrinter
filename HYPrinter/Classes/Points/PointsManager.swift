//
//  PointsManager.swift
//  HYPrinter
//

import Foundation
import UIKit

extension Notification.Name {
    static let pointsBalanceDidChange = Notification.Name("pointsBalanceDidChange")
    /// 首页悬浮签到 60 秒倒计时结束，签到页按钮可点。
    static let homeFloatingCheckInUnlocked = Notification.Name("homeFloatingCheckInUnlocked")
    /// 手动签到完成后：首页悬浮需重新倒计时。
    static let homeFloatingCheckInShouldRestart = Notification.Name("homeFloatingCheckInShouldRestart")
}

struct PointsLedgerEntry: Codable, Equatable {
    let id: String
    let date: Date
    let title: String
    let delta: Int
    let balanceAfter: Int
}

/// 积分：持久化、打印扣减、每日首次打开自动签到、手动签到。
final class PointsManager {

    static let shared = PointsManager()

    static let printCost = 5
    static let dailyAutoCheckInPoints = 100
    static let manualCheckInPoints = 20

    private let defaults = UserDefaults.standard
    private let balanceKey = "pm_balance"
    private let ledgerKey = "pm_ledger_v1"
    private let lastAutoCheckInDayKey = "pm_last_auto_checkin_day"

    private(set) var balance: Int = 0
    private var ledger: [PointsLedgerEntry] = []

    /// 当前进程内，首页悬浮倒计时是否已跑完（签到页依赖此状态）。
    private(set) var isHomeFloatingCheckInUnlocked = false

    private init() {
        load()
        isHomeFloatingCheckInUnlocked = false
    }

    func markHomeFloatingCheckInUnlocked() {
        guard !isHomeFloatingCheckInUnlocked else { return }
        isHomeFloatingCheckInUnlocked = true
        NotificationCenter.default.post(name: .homeFloatingCheckInUnlocked, object: nil)
    }

    private func load() {
        balance = defaults.object(forKey: balanceKey) as? Int ?? 0
        if let data = defaults.data(forKey: ledgerKey),
           let decoded = try? JSONDecoder().decode([PointsLedgerEntry].self, from: data) {
            ledger = decoded
        } else {
            ledger = []
        }
    }

    private func persistAndNotify() {
        defaults.set(balance, forKey: balanceKey)
        if let data = try? JSONEncoder().encode(ledger) {
            defaults.set(data, forKey: ledgerKey)
        }
        NotificationCenter.default.post(name: .pointsBalanceDidChange, object: nil)
    }

    private static func dayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// 每日首次进入前台：自动 +100 并返回提示文案；当日已处理则返回 nil。
    func processDailyFirstLaunchIfNeeded() -> String? {
        let today = Self.dayString(Date())
        let last = defaults.string(forKey: lastAutoCheckInDayKey)
        guard last != today else { return nil }
        defaults.set(today, forKey: lastAutoCheckInDayKey)
        applyDelta(PointsManager.dailyAutoCheckInPoints, title: "Daily first launch auto check-in")
        return "Auto check-in completed for today. You earned \(PointsManager.dailyAutoCheckInPoints) points."
    }

    /// 打印前扣减 5 积分；不足则弹窗并返回 false。
    @discardableResult
    func consumePrintPoints(from presenter: UIViewController?) -> Bool {
        guard balance >= PointsManager.printCost else {
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Insufficient Points",
                    message: "Each print costs \(PointsManager.printCost) points. You currently have \(self.balance) points.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                presenter?.present(alert, animated: true)
            }
            return false
        }
        applyDelta(-PointsManager.printCost, title: "Print cost")
        return true
    }

    /// 签到页手动签到：每次点击 +20（与每日首次打开自动 +100 独立）。
    func performManualSignIn() -> (ok: Bool, message: String) {
        applyDelta(PointsManager.manualCheckInPoints, title: "Manual check-in")
        resetHomeFloatingCheckInAfterManualSignIn()
        return (true, "You earned \(PointsManager.manualCheckInPoints) points!")
    }

    /// 手动签到成功后：关闭「可签到」状态并让首页悬浮重新进入 60 秒倒计时。
    private func resetHomeFloatingCheckInAfterManualSignIn() {
        isHomeFloatingCheckInUnlocked = false
        NotificationCenter.default.post(name: .homeFloatingCheckInShouldRestart, object: nil)
    }

    var ledgerEntriesSorted: [PointsLedgerEntry] {
        ledger.sorted { $0.date > $1.date }
    }

    private func applyDelta(_ delta: Int, title: String) {
        balance += delta
        let entry = PointsLedgerEntry(
            id: UUID().uuidString,
            date: Date(),
            title: title,
            delta: delta,
            balanceAfter: balance
        )
        ledger.append(entry)
        if ledger.count > 500 {
            ledger = Array(ledger.suffix(500))
        }
        persistAndNotify()
    }
}
