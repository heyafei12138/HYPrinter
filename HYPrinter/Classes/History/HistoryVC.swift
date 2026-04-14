//
//  HistoryVC.swift
//  HYPrinter
//

import UIKit

// MARK: - 顶部分组（文档 / 图片 / 其他）

private enum HistorySegmentTab: Int, CaseIterable {
    case document
    case image
    case other

    var title: String {
        switch self {
        case .document: return "文档"
        case .image: return "图片"
        case .other: return "其他"
        }
    }

    func contains(_ category: PrintHistoryCategory) -> Bool {
        switch self {
        case .document:
            return [.document, .text, .web, .contact].contains(category)
        case .image:
            return [.image, .sticker].contains(category)
        case .other:
            let known: [PrintHistoryCategory] = [.document, .text, .web, .contact, .image, .sticker]
            return !known.contains(category)
        }
    }
}

final class HistoryVC: BaseViewController {

    var pageHeaderTitle: String = "打印记录" {
        didSet { titleLabel.text = pageHeaderTitle }
    }

    override var shouldHideNavigationBar: Bool {
        get { true }
        set { }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 30)
        label.textColor = .black
        return label
    }()

    private lazy var segmentCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.register(HistorySegmentCell.self, forCellWithReuseIdentifier: HistorySegmentCell.reuseID)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.register(PrintHistoryCell.self, forCellReuseIdentifier: PrintHistoryCell.reuseID)
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 16, right: 0)
        return tv
    }()

    private let emptyContainer: UIView = {
        let v = UIView()
        v.isHidden = true
        v.backgroundColor = .clear
        return v
    }()

    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "empty_pla_image")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyHintLabel: UILabel = {
        let l = UILabel()
        l.text = ""
        l.font = kmiddleFont(fontSize: 15)
        l.textColor = UIColor(hexString: "#78818D")
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private var selectedSegment: HistorySegmentTab = .document
    private var displayedRecords: [PrintHistoryRecord] = []
    private var historyObserver: NSObjectProtocol?
    private var didPickInitialSegment = false

    override func buildSubviews() {
        super.buildSubviews()
        view.backgroundColor = UIColor(hexString: "#EEF1F7") ?? kBgColor
        titleLabel.text = pageHeaderTitle

        view.addSubview(titleLabel)
        view.addSubview(segmentCollection)
        view.addSubview(tableView)
        view.addSubview(emptyContainer)

        tableView.dataSource = self
        tableView.delegate = self

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        segmentCollection.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentCollection.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyContainer.snp.makeConstraints { make in
            make.top.equalTo(segmentCollection.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let emptyStack = UIStackView(arrangedSubviews: [emptyImageView, emptyHintLabel])
        emptyStack.axis = .vertical
        emptyStack.spacing = 16
        emptyStack.alignment = .center
        emptyContainer.addSubview(emptyStack)
        emptyImageView.snp.makeConstraints { make in
            make.width.height.equalTo(88)
        }
        emptyStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
            make.leading.greaterThanOrEqualToSuperview().inset(32)
            make.trailing.lessThanOrEqualToSuperview().inset(32)
        }
    }

    override func attachData() {
        super.attachData()
        reloadData()
        historyObserver = NotificationCenter.default.addObserver(
            forName: .printHistoryDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadData()
        }
    }

    deinit {
        if let historyObserver {
            NotificationCenter.default.removeObserver(historyObserver)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    private func reloadData() {
        let all = PrintHistoryStore.shared.allRecordsSorted()
        if !didPickInitialSegment {
            selectedSegment = Self.firstNonEmptySegment(in: all)
            didPickInitialSegment = true
        }
        displayedRecords = all.filter { selectedSegment.contains($0.category) }
        emptyContainer.isHidden = !displayedRecords.isEmpty
        tableView.isHidden = displayedRecords.isEmpty

   

        switch selectedSegment {
        case .document:
            emptyHintLabel.text = "暂无文档类打印记录\n如 PDF、网页、文本、联系人等将显示在这里"
        case .image:
            emptyHintLabel.text = "暂无图片类打印记录\n相册或贴纸打印将显示在这里"
        case .other:
            emptyHintLabel.text = "暂无其他类型打印记录"
        }
        segmentCollection.reloadData()
        tableView.reloadData()
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let idx = HistorySegmentTab.allCases.firstIndex(of: self.selectedSegment) else { return }
            let ip = IndexPath(item: idx, section: 0)
            self.segmentCollection.scrollToItem(at: ip, at: .centeredHorizontally, animated: false)
        }
    }

    private static func firstNonEmptySegment(in all: [PrintHistoryRecord]) -> HistorySegmentTab {
        for tab in HistorySegmentTab.allCases {
            if all.contains(where: { tab.contains($0.category) }) {
                return tab
            }
        }
        return .document
    }

    private func presentDeleteSheet(for record: PrintHistoryRecord, sourceView: UIView) {
        let alert = UIAlertController(title: nil, message: record.title, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            try? PrintHistoryStore.shared.deleteRecord(id: record.id)
            self?.reloadData()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = sourceView
            pop.sourceRect = sourceView.bounds
        }
        present(alert, animated: true)
    }
}

// MARK: - Segment

extension HistoryVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        HistorySegmentTab.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HistorySegmentCell.reuseID, for: indexPath) as? HistorySegmentCell else {
            return UICollectionViewCell()
        }
        let tab = HistorySegmentTab(rawValue: indexPath.item)!
        cell.configure(title: tab.title, selected: tab == selectedSegment)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tab = HistorySegmentTab(rawValue: indexPath.item)!
        guard tab != selectedSegment else { return }
        selectedSegment = tab
        reloadData()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let tab = HistorySegmentTab(rawValue: indexPath.item)!
        let font = kmiddleFont(fontSize: 14)
        let w = (tab.title as NSString).size(withAttributes: [.font: font]).width + 28
        return CGSize(width: max(56, ceil(w)), height: 34)
    }
}

private final class HistorySegmentCell: UICollectionViewCell {
    static let reuseID = "HistorySegmentCell"

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 8
        label.font = kmiddleFont(fontSize: 14)
        label.textAlignment = .center
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(12)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, selected: Bool) {
        label.text = title
        if selected {
            contentView.backgroundColor = kmainColor
            label.textColor = .white
            contentView.layer.borderWidth = 0
        } else {
            contentView.backgroundColor = .white
            label.textColor = UIColor(hexString: "#5B6472")
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = UIColor(hexString: "#E0E4EB")?.cgColor
        }
    }
}

// MARK: - Table

extension HistoryVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedRecords.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        96
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PrintHistoryCell.reuseID, for: indexPath) as? PrintHistoryCell else {
            return UITableViewCell()
        }
        let record = displayedRecords[indexPath.row]
        cell.configure(record: record) { [weak self] source in
            self?.presentDeleteSheet(for: record, sourceView: source)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let record = displayedRecords[indexPath.row]
        pushController(PrintHistoryDetailViewController(record: record))
    }
}

// MARK: - Cell

private final class PrintHistoryCell: UITableViewCell {
    static let reuseID = "PrintHistoryCell"

    private let cardView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 6
        s.alignment = .fill
        return s
    }()
    private let moreButton: UIButton = {
        let b = UIButton(type: .custom)
        let img = UIImage(named: "edit_more_ic")
        b.setImage(img, for: .normal)
        b.adjustsImageWhenHighlighted = true
        return b
    }()

    private var onMoreTap: ((UIView) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 8
        cardView.layer.masksToBounds = true

        iconView.contentMode = .scaleAspectFit
        titleLabel.font = kboldFont(fontSize: 16)
        titleLabel.textColor = UIColor(hexString: "#1D212C")
        titleLabel.numberOfLines = 2
        timeLabel.font = kmiddleFont(fontSize: 13)
        timeLabel.textColor = UIColor(hexString: "#78818D")
        subtitleLabel.font = kmiddleFont(fontSize: 12)
        subtitleLabel.textColor = UIColor(hexString: "#5B6472")
        subtitleLabel.numberOfLines = 2

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(timeLabel)
        textStack.addArrangedSubview(subtitleLabel)

        contentView.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(textStack)
        cardView.addSubview(moreButton)

        cardView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(6)
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(6)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalTo(moreButton.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
        }

        moreButton.addTarget(self, action: #selector(handleMore), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMoreTap = nil
    }

    @objc private func handleMore() {
        onMoreTap?(moreButton)
    }

    func configure(record: PrintHistoryRecord, onMoreTap: @escaping (UIView) -> Void) {
        self.onMoreTap = onMoreTap
        iconView.image = PrintHistoryIconProvider.rowIcon(for: record)
        titleLabel.text = record.title
        timeLabel.text = PrintHistoryDetailViewController.displayDateString(for: record.createdAt)
        if let sub = record.subtitle, !sub.isEmpty {
            subtitleLabel.isHidden = false
            subtitleLabel.text = sub
        } else {
            subtitleLabel.isHidden = true
            subtitleLabel.text = nil
        }
    }
}
