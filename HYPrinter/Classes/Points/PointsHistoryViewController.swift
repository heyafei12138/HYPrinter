//
//  PointsHistoryViewController.swift
//  HYPrinter
//

import UIKit

/// 积分变动明细
final class PointsHistoryViewController: BaseViewController {

    override var shouldHideNavigationBar: Bool {
        get { false }
        set { }
    }

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .singleLine
        tv.backgroundColor = .clear
        tv.register(PointsHistoryCell.self, forCellReuseIdentifier: PointsHistoryCell.reuseID)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 72
        return tv
    }()

    private var entries: [PointsLedgerEntry] = []

    private let activityFooterLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(hexString: "#5B6472")
        l.textAlignment = .left
        l.numberOfLines = 0
        l.text = """
        【当前活动说明】
        · 每日首次打开 App 自动获得 \(PointsManager.dailyAutoCheckInPoints) 积分。
        · 首页悬浮签到倒计时结束后可手动签到，每次 +\(PointsManager.manualCheckInPoints) 积分。
        · 每次打印消耗 \(PointsManager.printCost) 积分，明细见上表。
        """
        return l
    }()

    override func buildSubviews() {
        super.buildSubviews()
        title = "积分明细"
        allowsInteractivePop = true
        view.backgroundColor = UIColor(hexString: "#EEF1F7") ?? kBgColor

        view.addSubview(tableView)
        view.addSubview(activityFooterLabel)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(activityFooterLabel.snp.top).offset(-10)
        }
        activityFooterLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(14)
            make.top.greaterThanOrEqualTo(view.snp.centerY).priority(.high)
        }
        tableView.dataSource = self
        tableView.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .pointsBalanceDidChange, object: nil)
        reload()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func reload() {
        entries = PointsManager.shared.ledgerEntriesSorted
        tableView.reloadData()
        if entries.isEmpty {
            tableView.backgroundView = makeEmptyView()
        } else {
            tableView.backgroundView = nil
        }
    }

    private func makeEmptyView() -> UIView {
        let v = UIView()
        let l = UILabel()
        l.text = "暂无积分记录"
        l.textColor = UIColor(hexString: "#9AA4B2")
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textAlignment = .center
        v.addSubview(l)
        l.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return v
    }
}

extension PointsHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PointsHistoryCell.reuseID, for: indexPath) as! PointsHistoryCell
        cell.configure(entries[indexPath.row])
        return cell
    }
}

private final class PointsHistoryCell: UITableViewCell {
    static let reuseID = "PointsHistoryCell"

    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let deltaLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white

        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1D212C")
        titleLabel.numberOfLines = 0
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = UIColor(hexString: "#9AA4B2")
        deltaLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        deltaLabel.textAlignment = .right

        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(deltaLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(deltaLabel.snp.leading).offset(-8)
        }
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().inset(12)
        }
        deltaLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
            make.width.greaterThanOrEqualTo(56)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ entry: PointsLedgerEntry) {
        titleLabel.text = entry.title
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        dateLabel.text = f.string(from: entry.date)
        let sign = entry.delta >= 0 ? "+" : ""
        deltaLabel.text = "\(sign)\(entry.delta)"
        deltaLabel.textColor = entry.delta >= 0 ? (UIColor(hexString: "#1E9B70") ?? .systemGreen) : (UIColor(hexString: "#E53935") ?? .systemRed)
    }
}
