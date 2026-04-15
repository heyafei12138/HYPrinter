//
//  GreetingCardDetailViewController.swift
//  HYPrinter
//
//  横向预览 + 打印（对照 GreetingCardDetailVC，积分与历史与工程其它图片打印一致）
//

import UIKit

final class GreetingCardDetailViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    private let items: [CardItem]
    private let categoryTitle: String
    private var currentIndex: Int

    private let countLabel = UILabel()
    private let collectionView: UICollectionView
    private let printButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "printer_action"), for: .normal)
        return button
    }()
    init(items: [CardItem], categoryTitle: String, startIndex: Int = 0) {
        precondition(!items.isEmpty, "GreetingCardDetailViewController requires at least one item")
        self.items = items
        self.categoryTitle = categoryTitle
        self.currentIndex = max(0, min(startIndex, items.count - 1))
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func buildSubviews() {
        super.buildSubviews()
        title = "素材预览"
        view.backgroundColor = UIColor(hexString: "#EEF2F7")

        countLabel.textColor = UIColor(hexString: "#78818D")
        countLabel.font = kmiddleFont(fontSize: 12)
        countLabel.textAlignment = .center
        view.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(topBar.snp.bottom).offset(4)
        }

        topBar.addSubview(printButton)
       
        
        printButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(10)
            make.width.height.equalTo(24)
        }
        printButton.addTarget(self, action: #selector(printMaterial), for: .touchUpInside)
        
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GreetingCardPageCell.self, forCellWithReuseIdentifier: GreetingCardPageCell.identifier)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        updateCount()
        DispatchQueue.main.async { [weak self] in
            self?.scrollToCurrent()
        }
    }

    private func scrollToCurrent() {
        guard !items.isEmpty else { return }
        let index = IndexPath(item: currentIndex, section: 0)
        collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: false)
    }

    private func updateCount() {
        countLabel.text = "\(currentIndex + 1)/\(max(items.count, 1))"
    }

    @objc private func printMaterial() {
        let images: [UIImage] = items.compactMap { item in
            switch item.source {
            case .named(let name):
                return UIImage(named: name)
            case .fileURL(let url):
                return UIImage(contentsOfFile: url.path)
            }
        }
        guard !images.isEmpty else { return }
        guard PointsManager.shared.consumePrintPoints(from: self) else { return }

        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = appName
        printInfo.outputType = .photo
        printController.printInfo = printInfo
        printController.printingItems = images

        let title: String
        if images.count > 1 {
            title = "素材打印（\(images.count) 张）"
        } else {
            title = "素材打印"
        }
        try? PrintHistoryStore.shared.saveImagePrint(images: images, title: title, subtitle: categoryTitle)

        printController.present(animated: true, completionHandler: nil)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GreetingCardPageCell.identifier, for: indexPath) as? GreetingCardPageCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateIndexFromScroll()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateIndexFromScroll()
    }

    private func updateIndexFromScroll() {
        let page = Int(round(collectionView.contentOffset.x / max(collectionView.bounds.width, 1)))
        currentIndex = max(0, min(page, max(items.count - 1, 0)))
        updateCount()
    }
}

private final class GreetingCardPageCell: UICollectionViewCell {
    static let identifier = "GreetingCardPageCell"

    private let cardContainer = UIView()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cardContainer.backgroundColor = .white
        cardContainer.layer.cornerRadius = 8
        cardContainer.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(cardContainer)
        cardContainer.addSubview(imageView)
        cardContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.width.lessThanOrEqualToSuperview().offset(-32)
            make.height.lessThanOrEqualToSuperview().offset(-48)
        }
        let ratio: CGFloat = 1.4
        let h = cardContainer.heightAnchor.constraint(equalTo: cardContainer.widthAnchor, multiplier: ratio)
        h.priority = .required
        h.isActive = true
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: CardItem) {
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
