//
//  GreetingCardListViewController.swift
//  HYPrinter
//
//  首页「选素材」入口：分类列表（对照 GreetingCardListVC）
//

import UIKit

final class GreetingCardListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var categories: [CardCategory] = []

    override func buildSubviews() {
        super.buildSubviews()
        title = "Choose Templates"
        view.backgroundColor = UIColor(hexString: "#EEF2F7")

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GreetingCardCategoryRowCell.self, forCellReuseIdentifier: GreetingCardCategoryRowCell.identifier)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        categories = GreetingCardDataLoader.loadCategories()
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GreetingCardCategoryRowCell.identifier, for: indexPath) as? GreetingCardCategoryRowCell else {
            return UITableViewCell()
        }
        let cat = categories[indexPath.row]
        cell.configure(category: cat)
        cell.onPreviewTapped = { [weak self] item, _ in
            guard let self else { return }
            self.openDetail(for: item, category: cat)
        }
        cell.onSeeAllTapped = { [weak self] in
            guard let self else { return }
            let vc = GreetingCardLibraryViewController()
            vc.category = cat
            self.pushController(vc)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        54 + 142 + 24
    }

    private func openDetail(for item: CardItem, category: CardCategory) {
        let items = GreetingCardDetailItemsBuilder.detailItems(selected: item, category: category)
        let vc = GreetingCardDetailViewController(items: items, categoryTitle: category.title)
        pushController(vc)
    }
}

// MARK: - Row cell

private final class GreetingCardCategoryRowCell: UITableViewCell {
    static let identifier = "GreetingCardCategoryRowCell"

    private let container = UIView()
    private let titleLabel = UILabel()
    private let seeAllButton = UIButton(type: .custom)
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.itemSize = CGSize(width: 100, height: 142)
        let c = UICollectionView(frame: .zero, collectionViewLayout: layout)
        c.showsHorizontalScrollIndicator = false
        c.backgroundColor = .clear
        c.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
        c.dataSource = self
        c.delegate = self
        c.register(GreetingCardThumbCell.self, forCellWithReuseIdentifier: GreetingCardThumbCell.identifier)
        return c
    }()

    var onSeeAllTapped: (() -> Void)?
    var onPreviewTapped: ((CardItem, Int) -> Void)?

    private var items: [CardItem] = []

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
        titleLabel.font = kboldFont(fontSize: 18)
        titleLabel.textColor = UIColor(hexString: "#1D212C")
        seeAllButton.setTitle("›", for: .normal)
        seeAllButton.setTitleColor(UIColor(hexString: "#78818D"), for: .normal)
        seeAllButton.titleLabel?.font = kboldFont(fontSize: 20)
        seeAllButton.addTarget(self, action: #selector(handleSeeAll), for: .touchUpInside)
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSeeAll)))

        contentView.addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(seeAllButton)
        container.addSubview(collectionView)
    }

    private func setupConstraints() {
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 8, right: 0))
        }
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.height.equalTo(22)
        }
        seeAllButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.width.height.equalTo(24)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(142)
        }
    }

    func configure(category: CardCategory) {
        titleLabel.text = category.title
        items = category.items
        collectionView.reloadData()
    }

    @objc private func handleSeeAll() {
        onSeeAllTapped?()
    }
}

extension GreetingCardCategoryRowCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GreetingCardThumbCell.identifier, for: indexPath) as! GreetingCardThumbCell
        cell.configure(item: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onPreviewTapped?(items[indexPath.item], indexPath.item)
    }
}

private final class GreetingCardThumbCell: UICollectionViewCell {
    static let identifier = "GreetingCardThumbCell"

    private let bg = UIView()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        bg.backgroundColor = .white
        bg.layer.cornerRadius = 12
        bg.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(bg)
        bg.addSubview(imageView)
        bg.snp.makeConstraints { $0.edges.equalToSuperview() }
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(item: CardItem) {
        switch item.source {
        case .named(let name):
            imageView.image = UIImage(named: name)
        case .fileURL(let url):
            imageView.image = UIImage(contentsOfFile: url.path)
        }
        if imageView.image == nil {
            imageView.image = UIImage(named: "empty_pla_image")
        }
    }
}
