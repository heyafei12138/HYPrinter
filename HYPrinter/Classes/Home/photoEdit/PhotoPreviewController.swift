//
//  PhotoPreviewController.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/13.
//

import ZLImageEditor

final class PhotoPreviewController: BaseViewController {
    
    // MARK: - Display Mode
    
    private enum DisplayStyle {
        case focus
        case mosaic
    }
    
    // MARK: - Public Callback
    
    private(set) var photoItems: [UIImage]
    var didUpdatePhoto: ((Int, UIImage) -> Void)?
    var didTapPrint: (([UIImage]) -> Void)?
    var didTapClose: (() -> Void)?
    
    // MARK: - State
    
    private var displayStyle: DisplayStyle = .focus
    private var selectedPosition: Int = 0
    
    // MARK: - UI
    
    private let topContainer = UIView()
    private let headlineLabel = UILabel()
    private let pageIndicatorLabel = UILabel()
    private let layoutSwitchButton = UIButton(type: .custom)
    private let actionButton = UIButton(type: .custom)
    
    private var galleryView: UICollectionView!
    private let masonryLayout = MasonryFlowLayout()
    
    // MARK: - Init
    
    init(images: [UIImage]) {
        self.photoItems = images
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.photoItems = []
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString:"#EEF2F8")
        shouldHideNavigationBar = false
        
        setupTopSection()
        setupGalleryView()
        setupActionButton()
        refreshPageIndicator()
        refreshLayoutButtonIcon()
        refreshCollectionLayout()
    }
}

// MARK: - Build UI
private extension PhotoPreviewController {
    
    func setupTopSection() {
        title = nil
        topBar.backgroundColor = .clear
        topBar.updateBottomLine(hidden: true)
        
        view.addSubview(topContainer)
        topContainer.backgroundColor = .clear
        topContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview().inset(56)
            make.height.equalTo(56)
        }
        
        headlineLabel.text = "图像预览"
        headlineLabel.font = kboldFont(fontSize: 17)
        headlineLabel.textColor = UIColor(hexString:"#1D212C")
        
        pageIndicatorLabel.font = kmiddleFont(fontSize: 12)
        pageIndicatorLabel.textColor = UIColor(hexString:"#78818D")
        
        layoutSwitchButton.tintColor = UIColor(hexString:"#1D212C")
        layoutSwitchButton.addTarget(self, action: #selector(handleStyleSwitch), for: .touchUpInside)
        
        topContainer.addSubview(headlineLabel)
        topContainer.addSubview(pageIndicatorLabel)
        topBar.addSubview(layoutSwitchButton)
        
        headlineLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-8)
        }
        
        pageIndicatorLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(headlineLabel.snp.bottom).offset(2)
        }
        
        layoutSwitchButton.snp.makeConstraints { make in
            make.centerY.equalTo(topContainer)
            make.right.equalToSuperview().inset(16)
            make.size.equalTo(CGSize(width: 32, height: 32))
        }
    }
    
    func setupGalleryView() {
        let listLayout = UICollectionViewFlowLayout()
        listLayout.scrollDirection = .vertical
        listLayout.minimumLineSpacing = 12
        listLayout.minimumInteritemSpacing = 12
        
        galleryView = UICollectionView(frame: .zero, collectionViewLayout: listLayout)
        galleryView.backgroundColor = .clear
        galleryView.alwaysBounceVertical = true
        galleryView.showsVerticalScrollIndicator = false
        galleryView.dataSource = self
        galleryView.delegate = self
        galleryView.contentInset = UIEdgeInsets(top: 12, left: 16, bottom: 84, right: 16)
        galleryView.register(PreviewPhotoCell.self, forCellWithReuseIdentifier: PreviewPhotoCell.reuseID)
        
        view.addSubview(galleryView)
        galleryView.snp.makeConstraints { make in
            make.top.equalTo(topContainer.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    func setupActionButton() {
        actionButton.setTitle("打印", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = kboldFont(fontSize: 17)
        actionButton.backgroundColor = kmainColor
        actionButton.layer.cornerRadius = 24
        actionButton.layer.masksToBounds = true
        actionButton.addTarget(self, action: #selector(handlePrintAction), for: .touchUpInside)
        
        let hasData = !photoItems.isEmpty
        actionButton.isEnabled = hasData
        actionButton.alpha = hasData ? 1.0 : 0.5
        
        view.addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10)
            make.height.equalTo(48)
        }
    }
    
    func refreshCollectionLayout() {
        switch displayStyle {
        case .focus:
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = 12
            layout.minimumInteritemSpacing = 12
            galleryView.setCollectionViewLayout(layout, animated: false)
            galleryView.contentInset = UIEdgeInsets(top: 12, left: 16, bottom: 84, right: 16)
            
        case .mosaic:
            masonryLayout.numberOfColumns = 2
            masonryLayout.columnSpacing = 12
            masonryLayout.itemSpacing = 12
            masonryLayout.edgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 84, right: 16)
            masonryLayout.heightProvider = { [weak self] indexPath, width in
                guard let self = self else { return 120 }
                let image = self.photoItems[indexPath.item]
                let ratio = image.size.height / max(image.size.width, 1)
                return max(120, width * ratio)
            }
            galleryView.setCollectionViewLayout(masonryLayout, animated: false)
            galleryView.contentInset = .zero
        }
    }
    
    func refreshPageIndicator() {
        let totalCount = photoItems.count
        let current = min(max(selectedPosition, 0), max(totalCount - 1, 0))
        pageIndicatorLabel.text = "\(current + 1)/\(max(totalCount, 1))"
    }
    
    func refreshLayoutButtonIcon() {
        let iconName = (displayStyle == .focus)
        ? "vertical_ic"
        : "horizontal_ic"
        layoutSwitchButton.setImage(UIImage(named: iconName), for: .normal)
    }
}

// MARK: - Event
private extension PhotoPreviewController {
    
    @objc func handleStyleSwitch() {
        displayStyle = (displayStyle == .focus) ? .mosaic : .focus
        refreshLayoutButtonIcon()
        refreshCollectionLayout()
        galleryView.reloadData()
        
        guard selectedPosition < photoItems.count else { return }
        let target = IndexPath(item: selectedPosition, section: 0)
        DispatchQueue.main.async { [weak self] in
            self?.galleryView.scrollToItem(at: target, at: .centeredVertically, animated: true)
        }
    }
    
    @objc func handlePrintAction() {
       
        
        guard !photoItems.isEmpty else { return }
        
        didTapPrint?(photoItems)
        
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .photo
        info.jobName = "Printer"
        controller.printInfo = info
        controller.printingItems = photoItems
        controller.present(animated: true, completionHandler: nil)
        
//        let timeString = String.currentDateTime
//        let sizeString = photoItems.totalSizeString()
//        DBManager.shared.insertImages(
//            name: "photos" + timeString,
//            images: photoItems,
//            size: sizeString
//        )
        
    }
    
    func openEditor(at index: Int, image: UIImage) {
        configureEditorAppearance()
        
        let editorVC = ZLEditImageViewController(image: image)
        editorVC.editFinishBlock = { [weak self] editedImage, _ in
            guard let self = self else { return }
            self.photoItems[index] = editedImage
            self.didUpdatePhoto?(index, editedImage)
            self.galleryView.reloadItems(at: [IndexPath(item: index, section: 0)])
        }
        editorVC.modalPresentationStyle = .fullScreen
        present(editorVC, animated: true)
    }
    
    func configureEditorAppearance() {
        ZLImageEditorConfiguration.default()
            .editImageTools([.filter, .draw, .imageSticker, .textSticker, .mosaic, .adjust])
            .adjustTools([.brightness, .contrast, .saturation])
        
       
        
        ZLImageEditorUIConfiguration.default().editDoneBtnBgColor = kmainColor
        ZLImageEditorUIConfiguration.default().adjustSliderTintColor = kmainColor
    }
}

extension PhotoPreviewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedPosition = indexPath.item
        refreshPageIndicator()
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PreviewPhotoCell.reuseID,
            for: indexPath
        ) as? PreviewPhotoCell else {
            return UICollectionViewCell()
        }
        
        let image = photoItems[indexPath.item]
        cell.render(image: image) { [weak self] in
            self?.openEditor(at: indexPath.item, image: image)
        }
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let image = photoItems[indexPath.item]
        let maxWidth = view.bounds.width - 32
        let spacing = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 12
        
        switch displayStyle {
        case .focus:
            let width = maxWidth
            let ratio = image.size.height / max(image.size.width, 1)
            let height = max(180, width * ratio)
            return CGSize(width: width, height: height)
            
        case .mosaic:
            let width = (maxWidth - spacing) / 2
            let ratio = image.size.height / max(image.size.width, 1)
            let height = max(120, width * ratio)
            return CGSize(width: width, height: height)
        }
    }
}
final class MasonryFlowLayout: UICollectionViewLayout {
    
    var numberOfColumns: Int = 2
    var columnSpacing: CGFloat = 12
    var itemSpacing: CGFloat = 12
    var edgeInsets: UIEdgeInsets = .zero
    var heightProvider: ((_ indexPath: IndexPath, _ width: CGFloat) -> CGFloat)?
    
    private var cachedAttributes: [UICollectionViewLayoutAttributes] = []
    private var layoutContentHeight: CGFloat = 0
    
    private var layoutContentWidth: CGFloat {
        return collectionView?.bounds.width ?? 0
    }
    
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        
        cachedAttributes.removeAll()
        layoutContentHeight = 0
        
        let validWidth = layoutContentWidth - edgeInsets.left - edgeInsets.right
        let itemWidth = (validWidth - CGFloat(numberOfColumns - 1) * columnSpacing) / CGFloat(numberOfColumns)
        
        var xPositions: [CGFloat] = []
        for column in 0..<numberOfColumns {
            let originX = edgeInsets.left + CGFloat(column) * (itemWidth + columnSpacing)
            xPositions.append(originX)
        }
        
        var yPositions = Array(repeating: edgeInsets.top, count: numberOfColumns)
        
        let count = collectionView.numberOfItems(inSection: 0)
        for item in 0..<count {
            let indexPath = IndexPath(item: item, section: 0)
            
            let targetColumn = yPositions.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            let x = xPositions[targetColumn]
            let width = itemWidth
            let height = heightProvider?(indexPath, width) ?? 120
            
            let frame = CGRect(x: x, y: yPositions[targetColumn], width: width, height: height)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            
            cachedAttributes.append(attributes)
            
            yPositions[targetColumn] = frame.maxY + itemSpacing
            layoutContentHeight = max(layoutContentHeight, yPositions[targetColumn])
        }
        
        layoutContentHeight += edgeInsets.bottom
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: layoutContentWidth, height: layoutContentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cachedAttributes.filter { $0.frame.intersects(rect) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cachedAttributes.first(where: { $0.indexPath == indexPath })
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.size != collectionView?.bounds.size
    }
}
private final class PreviewPhotoCell: UICollectionViewCell {
    
    static let reuseID = "PreviewPhotoCell"
    
    private let cardView = UIView()
    private let previewImageView = UIImageView()
    private let editEntryButton = UIButton(type: .custom)
    
    private var editCallback: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildCellUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildCellUI()
    }
    
    private func buildCellUI() {
        contentView.backgroundColor = .clear
        
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.masksToBounds = true
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor(hexString:"#D9DBE1")!.cgColor
        
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        
        editEntryButton.setImage(UIImage(named: "ic_photo_edit"), for: .normal)
        editEntryButton.layer.cornerRadius = 4
        editEntryButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 0)
        editEntryButton.addTarget(self, action: #selector(handleEditTap), for: .touchUpInside)
        
        contentView.addSubview(cardView)
        cardView.addSubview(previewImageView)
        cardView.addSubview(editEntryButton)
        
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        previewImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        editEntryButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.right.equalToSuperview().inset(8)
            make.size.equalTo(CGSize(width: 32, height: 32))
        }
    }
    
    func render(image: UIImage, onEditTap: @escaping () -> Void) {
        previewImageView.image = image
        editCallback = onEditTap
    }
    
    @objc private func handleEditTap() {
        editCallback?()
    }
}
