//
//  StickerLibraryDetailViewController.swift
//  HYPrinter
//

import UIKit

/// 某一分类下全部贴纸（对照 LabelsLibraryDetailVC）
final class StickerLibraryDetailViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var category: StickerCategory?
    var gridPattern: GridPattern = GridPattern(rows: 3, columns: 2)

    private var collectionView: UICollectionView!

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No stickers yet"
        l.textAlignment = .center
        l.textColor = UIColor(hexString: "#78818D")
        l.font = kmiddleFont(fontSize: 14)
        l.isHidden = true
        return l
    }()

    override func buildSubviews() {
        super.buildSubviews()
        title = category?.title

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor(hexString: "#EEF1F7")
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(StickerGridCell.self, forCellWithReuseIdentifier: StickerGridCell.identifier)

        view.backgroundColor = UIColor(hexString: "#EEF1F7")
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topBar.snp.bottom)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let count = category?.items.count ?? 0
        emptyLabel.isHidden = count > 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        category?.items.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerGridCell.identifier, for: indexPath) as? StickerGridCell,
              let item = category?.items[indexPath.item] else {
            return UICollectionViewCell()
        }
        cell.configure(with: item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cat = category else { return }
        let item = cat.items[indexPath.item]
        let vc = StickerItemPreviewViewController()
        vc.item = item
        vc.gridPattern = gridPattern
        pushController(vc)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let columns: CGFloat = 3
        let inset = collectionView.contentInset
        let spacing: CGFloat = 12
        let totalSpacing = spacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - inset.left - inset.right - totalSpacing
        let itemWidth = floor(availableWidth / columns)
        return CGSize(width: itemWidth, height: itemWidth)
    }
}

// MARK: - Cell

private final class StickerGridCell: UICollectionViewCell {
    static let identifier = "StickerGridCell"

    private let container = UIView()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true

        contentView.addSubview(container)
        container.addSubview(imageView)

        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.lessThanOrEqualToSuperview()
        }
    }

    func configure(with item: StickerItem) {
        switch item.source {
        case .named(let name):
            imageView.image = UIImage(named: name)
        case .fileURL(let url):
            imageView.image = UIImage(contentsOfFile: url.path)
        }
        if imageView.image == nil {
            imageView.image = UIImage(named: "label_home_icon")
        }
    }
}
