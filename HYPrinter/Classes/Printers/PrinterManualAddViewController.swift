//
//  PrinterManualAddViewController.swift
//  HYPrinter
//
//  Created by Codex on 2026/4/11.
//

import UIKit

private struct ManualPrinterBrand {
    let name: String
    let models: [String]
}

private enum ManualPrinterCatalog {
    static let brands: [ManualPrinterBrand] = [
        ManualPrinterBrand(name: "Brother", models: ["DCP-T420W", "HL-L2350DW", "MFC-L2710DW"]),
        ManualPrinterBrand(name: "Canon", models: ["G3810", "TS3380", "TR8620a"]),
        ManualPrinterBrand(name: "Epson", models: ["L3256", "L4266", "WF-2930"]),
        ManualPrinterBrand(name: "HP", models: ["DeskJet 2720", "LaserJet MFP M233dw", "OfficeJet Pro 9010"]),
        ManualPrinterBrand(name: "Pantum", models: ["P2500W", "M6500W", "M7105DN"]),
        ManualPrinterBrand(name: "Xiaomi", models: ["Mi Inkjet All-in-One", "Mi Portable Photo Printer", "Mi Pocket Printer"]),
        ManualPrinterBrand(name: "Xerox", models: ["B210", "C230", "WorkCentre 3025"]),
        ManualPrinterBrand(name: "Zebra", models: ["ZD220", "ZD421", "ZT230"])
    ]
}

final class PrinterManualAddViewController: BaseViewController {
    
    var onSelected: ((String, String) -> Void)?
    
    override var allowsInteractivePop: Bool {
        get { true }
        set { }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Printer Brand"
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .black
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "After manual add, the device will appear in the list as offline first."
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hexString: "#707A89") ?? .gray
        label.numberOfLines = 0
        return label
    }()
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let brands = ManualPrinterCatalog.brands.sorted {
        $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Manual Add"
    }
    
    override func buildSubviews() {
        super.buildSubviews()
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(tableView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        tableView.register(ManualPrinterBrandCell.self, forCellReuseIdentifier: ManualPrinterBrandCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
    }
}

extension PrinterManualAddViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        brands.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ManualPrinterBrandCell.reuseIdentifier,
            for: indexPath
        ) as? ManualPrinterBrandCell else {
            return UITableViewCell()
        }
        
        cell.configure(title: brands[indexPath.row].name)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let brand = brands[indexPath.row]
        let modelVC = PrinterModelSelectionViewController(brand: brand)
        modelVC.onSelected = { [weak self] brandName, modelName in
            self?.onSelected?(brandName, modelName)
            self?.navigationController?.popToRootViewController(animated: true)
        }
        navigationController?.pushViewController(modelVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }
}

private final class PrinterModelSelectionViewController: BaseViewController {
    
    var onSelected: ((String, String) -> Void)?
    
    override var allowsInteractivePop: Bool {
        get { true }
        set { }
    }
    
    private let brand: ManualPrinterBrand
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Printer Model"
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .black
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "\(brand.name) Popular Models"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hexString: "#707A89") ?? .gray
        return label
    }()
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    init(brand: ManualPrinterBrand) {
        self.brand = brand
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Model"
    }
    
    override func buildSubviews() {
        super.buildSubviews()
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(tableView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        tableView.register(ManualPrinterBrandCell.self, forCellReuseIdentifier: ManualPrinterBrandCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
    }
}

extension PrinterModelSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        brand.models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ManualPrinterBrandCell.reuseIdentifier,
            for: indexPath
        ) as? ManualPrinterBrandCell else {
            return UITableViewCell()
        }
        
        cell.configure(title: brand.models[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelected?(brand.name, brand.models[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }
}

private final class ManualPrinterBrandCell: UITableViewCell {
    
    static let reuseIdentifier = "ManualPrinterBrandCell"
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()
    
    private let arrowView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = UIColor(hexString: "#9AA4B2") ?? .lightGray
        imageView.contentMode = .scaleAspectFit
        return imageView
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
    
    func configure(title: String) {
        titleLabel.text = title
    }
    
    private func buildSubviews() {
        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(arrowView)
        
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(arrowView.snp.left).offset(-12)
        }
        
        arrowView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
    }
}
