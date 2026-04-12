//
//  PrintersVC.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//

import UIKit
import Lottie

final class PrintersVC: BaseViewController {
    
    private enum ViewState {
        case searching
        case list
        case empty
        case failed(String)
    }
    
    var pageHeaderTitle: String = "掌上打印" {
        didSet {
            titleLabel.text = pageHeaderTitle
        }
    }
    
    override var shouldHideNavigationBar: Bool {
        get { true }
        set { }
    }
    
    private let discoveryService = PrinterDiscoveryService.shared
    
    private var onlinePrinters: [PrinterDevice] = []
    private var offlinePrinters: [PrinterDevice] = []
    private var state: ViewState = .searching
    private var pendingFailureMessage: String?
    private var localNetworkAuthorizer: PrinterLocalNetworkAuthorizer?
    private var searchTimeoutWorkItem: DispatchWorkItem?
    private let searchTimeoutInterval: TimeInterval = 10.5
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .black
        return label
    }()
    
    private let refreshButton: UIButton = {
        let button = UIButton(type: .custom)
//        button.tintColor = kmainColor
        button.backgroundColor = .white
        button.layer.cornerRadius = 18
        button.setImage(UIImage(named: "refresh_printer"), for: .normal)
        return button
    }()
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let stateContainerView = UIView()
    
    private let searchingView = PrinterSearchingStateView()
    private let emptyView = PrinterEmptyStateView()
    private let failedView = PrinterFailedStateView()
    
    private let manualAddButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("手动添加设备", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        button.setBackgroundImage(UIImage(named: "continue_btn_bg_new"), for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private var sections: [PrinterSection] {
        var result: [PrinterSection] = []
        if !onlinePrinters.isEmpty {
            result.append(.online)
        }
        if !offlinePrinters.isEmpty {
            result.append(.offline)
        }
        return result
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        discoveryService.delegate = self
        reloadPrinterGroups(with: discoveryService.currentPrinters())
        applyState(sections.isEmpty ? .searching : .list)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        discoveryService.delegate = self
        startSearchingPrinters(silently: sections.isEmpty == false)
    }
    
    deinit {
        cancelSearchTimeout()
        localNetworkAuthorizer?.cancel()
        NotificationCenter.default.removeObserver(self)
        if discoveryService.delegate === self {
            discoveryService.delegate = nil
        }
    }
    
    override func buildSubviews() {
        super.buildSubviews()
        
        titleLabel.text = pageHeaderTitle
        view.addSubview(titleLabel)
        view.addSubview(refreshButton)
        view.addSubview(tableView)
        view.addSubview(stateContainerView)
        view.addSubview(manualAddButton)
        
        stateContainerView.addSubview(searchingView)
        stateContainerView.addSubview(emptyView)
        stateContainerView.addSubview(failedView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.left.equalToSuperview().offset(16)
        }
        
        refreshButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().inset(16)
            make.width.height.equalTo(30)
        }
        
        manualAddButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(36)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(30)
            make.height.equalTo(56)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(manualAddButton.snp.top).offset(-12)
        }
        
        stateContainerView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
        
        searchingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        failedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        configureTableView()
        bindActions()
        applyState(.searching)
    }
}

private extension PrintersVC {
    
    enum PrinterSection {
        case online
        case offline
        
        var title: String {
            switch self {
            case .online:
                return "可用设备"
            case .offline:
                return "其他设备"
            }
        }
    }
    
    func configureTableView() {
        tableView.register(PrinterDeviceCell.self, forCellReuseIdentifier: PrinterDeviceCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }
    
    func bindActions() {
        refreshButton.addTarget(self, action: #selector(handleRefreshTap), for: .touchUpInside)
        manualAddButton.addTarget(self, action: #selector(handleManualAddTap), for: .touchUpInside)
        
        emptyView.onRefreshTap = { [weak self] in
            self?.startSearchingPrinters()
        }
        emptyView.onHelpTap = { [weak self] in
            self?.presentPossibleCauses()
        }
        failedView.onPrimaryTap = { [weak self] in
            self?.handleFailedPrimaryAction()
        }
    }
    
    func startSearchingPrinters(silently: Bool = false) {
        pendingFailureMessage = nil
        let shouldKeepListVisible = silently && sections.isEmpty == false
        cancelSearchTimeout()
        localNetworkAuthorizer?.cancel()
        localNetworkAuthorizer = nil
        
        if shouldKeepListVisible {
            applyState(.list)
        } else {
            applyState(.searching)
            scheduleSearchTimeout()
        }
        
        if #available(iOS 14.0, *) {
            let authorizer = PrinterLocalNetworkAuthorizer()
            localNetworkAuthorizer = authorizer
            authorizer.requestAuthorization { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.localNetworkAuthorizer = nil
                    if granted {
                        self.discoveryService.startDiscovery()
                    } else {
                        self.discoveryService.stopDiscovery(notify: false)
                        self.reloadPrinterGroups(with: self.discoveryService.currentPrinters())
                        if shouldKeepListVisible == false {
                            self.applyState(.failed("请在系统设置中开启“本地网络”权限后再搜索打印机。"))
                        }
                    }
                }
            }
        } else {
            discoveryService.startDiscovery()
        }
    }
    
    func scheduleSearchTimeout() {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard case .searching = self.state else { return }
            
            self.localNetworkAuthorizer?.cancel()
            self.localNetworkAuthorizer = nil
            self.discoveryService.stopDiscovery(notify: false)
            self.reloadPrinterGroups(with: self.discoveryService.currentPrinters())
            self.tableView.reloadData()
            
            if self.sections.isEmpty {
                if let pendingFailureMessage = self.pendingFailureMessage {
                    self.applyState(.failed(pendingFailureMessage))
                } else {
                    self.applyState(.empty)
                }
            } else {
                self.applyState(.list)
            }
        }
        
        searchTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + searchTimeoutInterval, execute: workItem)
    }
    
    func cancelSearchTimeout() {
        searchTimeoutWorkItem?.cancel()
        searchTimeoutWorkItem = nil
    }
    
    func reloadPrinterGroups(with printers: [PrinterDevice]) {
        var bestByDeviceKey: [String: PrinterDevice] = [:]
        
        for printer in printers {
            let host = normalizedHost(for: printer.url)
            let key = "\(printer.name)|\(host)"
            
            if let existing = bestByDeviceKey[key] {
                bestByDeviceKey[key] = preferredPrinter(between: existing, and: printer)
            } else {
                bestByDeviceKey[key] = printer
            }
        }
        
        let dedupedPrinters = Array(bestByDeviceKey.values)
        onlinePrinters = dedupedPrinters
            .filter(\.isConnected)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        offlinePrinters = dedupedPrinters
            .filter { !$0.isConnected }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    func preferredPrinter(between lhs: PrinterDevice, and rhs: PrinterDevice) -> PrinterDevice {
        func score(for printer: PrinterDevice) -> Int {
            let scheme = printer.url.scheme?.lowercased() ?? ""
            let port = printer.url.port ?? 0
            
            if scheme == "ipp" && port == 631 { return 100 }
            if scheme == "ipps" && port == 631 { return 90 }
            if port == 9100 { return 70 }
            if scheme == "manual" { return 20 }
            return 10
        }
        
        return score(for: lhs) >= score(for: rhs) ? lhs : rhs
    }
    
    func normalizedHost(for url: URL) -> String {
        let host = url.host ?? url.absoluteString
        return host
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
    }
    
    private func applyState(_ newState: ViewState) {
        state = newState
        tableView.isHidden = true
        stateContainerView.isHidden = false
        searchingView.isHidden = true
        emptyView.isHidden = true
        failedView.isHidden = true
        
        switch newState {
        case .searching:
            searchingView.isHidden = false
        case .list:
            tableView.isHidden = false
            stateContainerView.isHidden = true
        case .empty:
            emptyView.isHidden = false
        case .failed(let message):
            failedView.configure(message: message)
            failedView.isHidden = false
        }
    }
    
    func presentPossibleCauses() {
        let message = [
            "1. 请确认打印机和手机处于同一局域网。",
            "2. 请确认打印机已开机且支持局域网发现。",
            "3. 如局域网权限被关闭，请前往系统设置开启。"
        ].joined(separator: "\n")
        
        let alert = UIAlertController(title: "可能原因", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .cancel))
        present(alert, animated: true)
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    func handleFailedPrimaryAction() {
        if case .failed(let message) = state,
           message.contains("本地网络") {
            openAppSettings()
        } else {
            startSearchingPrinters()
        }
    }
    
    @objc func handleRefreshTap() {
        startSearchingPrinters()
    }
    
    @objc func handleManualAddTap() {
        let addVC = PrinterManualAddViewController()
        addVC.onSelected = { [weak self] brand, model in
            guard let self else { return }
            self.discoveryService.addManualPrinter(name: "\(brand) \(model)")
            self.reloadPrinterGroups(with: self.discoveryService.currentPrinters())
            self.tableView.reloadData()
            self.applyState(.list)
        }
        pushController(addVC)
        
    }
    
    @objc func handleAppDidBecomeActive() {
        discoveryService.delegate = self
    }
}

extension PrintersVC: PrinterDiscoveryServiceDelegate {
    
    func printerDiscoveryService(_ service: PrinterDiscoveryService, didUpdate printers: [PrinterDevice]) {
        reloadPrinterGroups(with: printers)
        tableView.reloadData()
        
        if !sections.isEmpty {
            cancelSearchTimeout()
            applyState(.list)
        }
    }
    
    func printerDiscoveryService(_ service: PrinterDiscoveryService, didChangeSearching isSearching: Bool) {
        guard isSearching == false else {
            return
        }
        
        cancelSearchTimeout()
        
        if sections.isEmpty {
            if let pendingFailureMessage {
                applyState(.failed(pendingFailureMessage))
            } else {
                applyState(.empty)
            }
        } else {
            applyState(.list)
        }
    }
    
    func printerDiscoveryService(_ service: PrinterDiscoveryService, didFail message: String) {
        pendingFailureMessage = message
    }
}

extension PrintersVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .online:
            return onlinePrinters.count
        case .offline:
            return offlinePrinters.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PrinterDeviceCell.reuseIdentifier,
            for: indexPath
        ) as? PrinterDeviceCell else {
            return UITableViewCell()
        }
        
        let printer: PrinterDevice
        switch sections[indexPath.section] {
        case .online:
            printer = onlinePrinters[indexPath.row]
        case .offline:
            printer = offlinePrinters[indexPath.row]
        }
        
        cell.configure(with: printer)
        return cell
    }
}

extension PrintersVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        92
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        36
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let label = UILabel()
        label.text = sections[section].title
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(hexString: "#5B6472") ?? .darkGray
        
        headerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().inset(6)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == sections.count - 1 ? 184 : 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == sections.count - 1 else { return nil }
        
        let containerView = UIView()
        containerView.backgroundColor = .clear
        let tipsView = PrinterTipsCardView(
            title: "查找不到设备？",
            items: [
                "确认打印机已经连接到 Wi-Fi 或局域网。",
                "确认手机和打印机处于同一个网络环境。",
                "如仍未搜到，可手动添加常用机型。"
            ]
        )
        containerView.addSubview(tipsView)
        tipsView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.right.equalToSuperview().inset(16)
        }
        return containerView
    }
}

private final class PrinterDeviceCell: UITableViewCell {
    
    static let reuseIdentifier = "PrinterDeviceCell"
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let iconBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = (kBgColor ?? UIColor.systemGray6).withAlphaComponent(0.95)
        view.layer.cornerRadius = 24
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "printer.fill"))
        imageView.tintColor = kmainColor ?? .systemBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(hexString: "#7B8492") ?? .gray
        return label
    }()
    
    private let statusLabel: PaddingLabel = {
        let label = PaddingLabel(insets: UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10))
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        buildSubviews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with printer: PrinterDevice) {
        nameLabel.text = printer.name
        detailLabel.text = printer.isManual ? "已手动添加" : (printer.url.host ?? printer.url.absoluteString)
        
        if printer.isConnected {
            statusLabel.text = "可用"
            statusLabel.textColor = UIColor(hexString: "#1E9B70") ?? .systemGreen
            statusLabel.backgroundColor = UIColor(hexString: "#E6F7F1") ?? UIColor.systemGreen.withAlphaComponent(0.12)
        } else {
            statusLabel.text = "未连接"
            statusLabel.textColor = UIColor(hexString: "#8A94A6") ?? .gray
            statusLabel.backgroundColor = UIColor(hexString: "#EEF1F6") ?? UIColor.systemGray5
        }
    }
    
    private func buildSubviews() {
        contentView.addSubview(cardView)
        cardView.addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(detailLabel)
        cardView.addSubview(statusLabel)
        
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16))
        }
        
        iconBackgroundView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(iconBackgroundView.snp.right).offset(12)
            make.top.equalToSuperview().offset(18)
            make.right.lessThanOrEqualTo(statusLabel.snp.left).offset(-8)
        }
        
        detailLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.right.lessThanOrEqualTo(statusLabel.snp.left).offset(-8)
        }
    }
}

private final class PrinterSearchingStateView: UIView {
    
    private let loadingView: LottieAnimationView = {
        let view = LottieAnimationView(name: "Loading_animation_blue")
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "正在查找打印机"
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.text = "请保持手机和打印机在同一网络环境中。"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hexString: "#707A89") ?? .gray
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let tipsView = PrinterTipsCardView(
        title: "搜索前请确认",
        items: [
            "打印机已开机并连接网络。",
            "手机已允许本地网络权限。",
            "如设备未显示，可尝试手动添加。"
        ]
    )
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildSubviews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildSubviews() {
        backgroundColor = .clear
        loadingView.play()
        
        addSubview(loadingView)
        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(tipsView)
        
        loadingView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(72)
            make.width.height.equalTo(132)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(loadingView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(24)
        }
        
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(32)
        }
        
        tipsView.snp.makeConstraints { make in
            make.top.equalTo(detailLabel.snp.bottom).offset(28)
            make.left.right.equalToSuperview().inset(16)
        }
    }
}

private final class PrinterEmptyStateView: UIView {
    
    var onRefreshTap: (() -> Void)?
    var onHelpTap: (() -> Void)?
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "printer.slash"))
        imageView.tintColor = UIColor(hexString: "#AAB2BF") ?? .lightGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "未找到打印机"
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.text = "搜索完成后仍未发现可用设备，你可以重试或查看排查建议。"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hexString: "#707A89") ?? .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("重新搜索", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = kmainColor ?? .systemBlue
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let helpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("查看排查建议", for: .normal)
        button.setTitleColor(kmainColor ?? .systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildSubviews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildSubviews() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(refreshButton)
        addSubview(helpButton)
        
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(72)
            make.width.height.equalTo(72)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(18)
            make.left.right.equalToSuperview().inset(24)
        }
        
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(32)
        }
        
        refreshButton.snp.makeConstraints { make in
            make.top.equalTo(detailLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(136)
            make.height.equalTo(40)
        }
        
        helpButton.snp.makeConstraints { make in
            make.top.equalTo(refreshButton.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        
        refreshButton.addTarget(self, action: #selector(handleRefreshTap), for: .touchUpInside)
        helpButton.addTarget(self, action: #selector(handleHelpTap), for: .touchUpInside)
    }
    
    @objc private func handleRefreshTap() {
        onRefreshTap?()
    }
    
    @objc private func handleHelpTap() {
        onHelpTap?()
    }
}

private final class PrinterFailedStateView: UIView {
    
    var onPrimaryTap: (() -> Void)?
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        imageView.tintColor = UIColor(hexString: "#F3A23D") ?? .systemOrange
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "查找失败"
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hexString: "#707A89") ?? .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let primaryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = kmainColor ?? .systemBlue
        button.layer.cornerRadius = 20
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildSubviews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(message: String) {
        detailLabel.text = message
        let title = message.contains("本地网络") ? "打开设置" : "重新搜索"
        primaryButton.setTitle(title, for: .normal)
    }
    
    private func buildSubviews() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(primaryButton)
        
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(72)
            make.width.height.equalTo(72)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(18)
            make.left.right.equalToSuperview().inset(24)
        }
        
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(32)
        }
        
        primaryButton.snp.makeConstraints { make in
            make.top.equalTo(detailLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(136)
            make.height.equalTo(40)
        }
        
        primaryButton.addTarget(self, action: #selector(handlePrimaryTap), for: .touchUpInside)
    }
    
    @objc private func handlePrimaryTap() {
        onPrimaryTap?()
    }
}

private final class PrinterTipsCardView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }()
    
    init(title: String, items: [String]) {
        super.init(frame: .zero)
        titleLabel.text = title
        buildSubviews(with: items)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildSubviews(with items: [String]) {
        backgroundColor = UIColor(hexString: "#FFFFFF") ?? .white
        layer.cornerRadius = 20
        
        addSubview(titleLabel)
        addSubview(stackView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview().inset(16)
        }
        
        for item in items {
            let row = UILabel()
            row.text = "• \(item)"
            row.font = .systemFont(ofSize: 14)
            row.textColor = UIColor(hexString: "#556070") ?? .darkGray
            row.numberOfLines = 0
            stackView.addArrangedSubview(row)
        }
    }
}

private final class PaddingLabel: UILabel {
    
    private let contentInsets: UIEdgeInsets
    
    init(insets: UIEdgeInsets) {
        self.contentInsets = insets
        super.init(frame: .zero)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}
