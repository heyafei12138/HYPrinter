//
//  StickerLibraryViewController.swift
//  HYPrinter
//

import UIKit

/// 贴纸分类列表（对照 LabelsLibraryViewController）
final class StickerLibraryViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    var gridPattern: GridPattern = GridPattern(rows: 3, columns: 2)

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var categories: [StickerCategory] = []

    override func buildSubviews() {
        super.buildSubviews()
        title = "选择贴纸"
        view.backgroundColor = UIColor(hexString: "#EEF1F7")

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        tableView.register(StickerCategoryRowCell.self, forCellReuseIdentifier: StickerCategoryRowCell.identifier)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        categories = StickerLocalDataSource.loadCategories()
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StickerCategoryRowCell.identifier, for: indexPath) as? StickerCategoryRowCell else {
            return UITableViewCell()
        }
        let category = categories[indexPath.row]
        cell.configure(category: category)
        cell.onSeeAllTapped = { [weak self] in
            guard let self else { return }
            let vc = StickerLibraryDetailViewController()
            vc.category = category
            vc.gridPattern = self.gridPattern
            self.pushController(vc)
        }
        cell.onPreviewTapped = { [weak self] item in
            guard let self else { return }
            let vc = StickerItemPreviewViewController()
            vc.item = item
            vc.gridPattern = self.gridPattern
            self.pushController(vc)
        }
        return cell
    }
}

// MARK: - Category row

private final class StickerCategoryRowCell: UITableViewCell {
    static let identifier = "StickerCategoryRowCell"

    private let container = UIView()
    private let titleLabel = UILabel()
    private let seeAllButton = UIButton(type: .custom)
    private var collectionView: UICollectionView!

    var onSeeAllTapped: (() -> Void)?
    var onPreviewTapped: ((StickerItem) -> Void)?

    private var previewItems: [StickerItem] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        container.backgroundColor = .clear
        container.layer.cornerRadius = 24
        container.layer.masksToBounds = true

        titleLabel.font = kboldFont(fontSize: 16)
        titleLabel.textColor = UIColor(hexString: "#1D212C")

        seeAllButton.setTitle("›", for: .normal)
        seeAllButton.setTitleColor(UIColor(hexString: "#78818D"), for: .normal)
        seeAllButton.titleLabel?.font = kboldFont(fontSize: 20)
        seeAllButton.addTarget(self, action: #selector(handleSeeAll), for: .touchUpInside)
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSeeAll)))

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.itemSize = CGSize(width: 100, height: 100)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(StickerThumbCell.self, forCellWithReuseIdentifier: StickerThumbCell.identifier)

        contentView.addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(seeAllButton)
        container.addSubview(collectionView)
    }

    private func setupConstraints() {
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(8)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(6)
        }
        seeAllButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.centerY.equalTo(titleLabel).offset(-1)
            make.width.height.equalTo(24)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().inset(12)
            make.height.equalTo(100)
        }
    }

    func configure(category: StickerCategory) {
        titleLabel.text = category.title
        previewItems = category.items
        collectionView.reloadData()
    }

    @objc private func handleSeeAll() {
        onSeeAllTapped?()
    }
}

extension StickerCategoryRowCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        previewItems.isEmpty ? 1 : previewItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerThumbCell.identifier, for: indexPath) as! StickerThumbCell
        if previewItems.isEmpty {
            cell.configurePlaceholder()
        } else {
            cell.configure(with: previewItems[indexPath.item])
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !previewItems.isEmpty else { return }
        onPreviewTapped?(previewItems[indexPath.item])
    }
}

// MARK: - Thumb cell

private final class StickerThumbCell: UICollectionViewCell {
    static let identifier = "StickerThumbCell"

    private let bg = UIView()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        bg.backgroundColor = .white
        bg.layer.cornerRadius = 16
        bg.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(bg)
        bg.addSubview(imageView)
        bg.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(100)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        bg.subviews.filter { $0 is UILabel }.forEach { $0.removeFromSuperview() }
    }

    func configure(with item: StickerItem) {
        bg.subviews.compactMap { $0 as? UILabel }.forEach { $0.removeFromSuperview() }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var image: UIImage?
            switch item.source {
            case .named(let name):
                image = UIImage(named: name)
            case .fileURL(let url):
                image = UIImage(contentsOfFile: url.path)
            }
            if image == nil {
                image = UIImage(named: "label_home_icon")
            }
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }
    }

    func configurePlaceholder() {
        imageView.image = nil
        let label = UILabel()
        label.text = "暂无"
        label.textAlignment = .center
        label.textColor = UIColor(hexString: "#78818D")
        label.font = kmiddleFont(fontSize: 12)
        bg.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
