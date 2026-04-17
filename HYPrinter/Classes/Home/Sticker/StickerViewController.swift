//
//  StickerViewController.swift
//  HYPrinter
//

import ObjectiveC
import PhotosUI
import UIKit
import ZLImageEditor

/// 标签纸形状与排版模板选择，下一步进入贴纸库或相册（对照 LabelsListViewController）
final class StickerViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let categoryContainer = UIView()
    private var categoryCollection: UICollectionView!

    private var templatesCollection: UICollectionView!
    private let templatesContainer = UIView()

    private let nextButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("Next", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = kboldFont(fontSize: 17)
        b.backgroundColor = UIColor(hexString: "#BFC7D2")
        b.layer.cornerRadius = 24
        b.isEnabled = false
        return b
    }()

    private let categories = StickerSheetShape.allCases
    private var selectedShape: StickerSheetShape = .rectangle
    private var templates: [StickerSheetTemplate] = []
    private var selectedTemplateIndex: IndexPath?
    private var selectedIndexForShape: [StickerSheetShape: IndexPath] = [:]

    override func buildSubviews() {
        super.buildSubviews()
        title = "Stickers"
        view.backgroundColor = UIColor(hexString: "#EEF1F7") ?? kBgColor

        setupCategoryBar()
        setupTemplatesGrid()
        setupNextButton()
        reloadTemplates()
    }

    private func setupCategoryBar() {
        view.addSubview(categoryContainer)
        categoryContainer.backgroundColor = .clear
        categoryContainer.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.estimatedItemSize = .zero

        categoryCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        categoryCollection.backgroundColor = .clear
        categoryCollection.showsHorizontalScrollIndicator = false
        categoryCollection.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        categoryCollection.dataSource = self
        categoryCollection.delegate = self
        categoryCollection.register(StickerChipCell.self, forCellWithReuseIdentifier: StickerChipCell.identifier)
        categoryContainer.addSubview(categoryCollection)
        categoryCollection.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupTemplatesGrid() {
        view.addSubview(templatesContainer)
        templatesContainer.backgroundColor = .clear
        templatesContainer.snp.makeConstraints { make in
            make.top.equalTo(categoryContainer.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(80)
        }

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        templatesCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        templatesCollection.backgroundColor = .clear
        templatesCollection.showsVerticalScrollIndicator = false
        templatesCollection.dataSource = self
        templatesCollection.delegate = self
        templatesCollection.register(StickerTemplateCell.self, forCellWithReuseIdentifier: StickerTemplateCell.identifier)
        templatesContainer.addSubview(templatesCollection)
        templatesCollection.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupNextButton() {
        view.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(48)
        }
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
    }

    @objc private func handleNext() {
        guard let idx = selectedTemplateIndex else { return }
        let tpl = templates[idx.item]

        let choose = StickerChooseViewController()
        choose.modalPresentationStyle = .overFullScreen
        present(choose, animated: true)

        choose.onChoose = { [weak self] choice in
            guard let self else { return }
            switch choice {
            case .photoLibrary:
                self.selectImage(template: tpl)
            case .stickerLibrary:
                let lib = StickerLibraryViewController()
                lib.gridPattern = tpl.pattern
                self.pushController(lib)
            }
        }
    }

    private func reloadTemplates() {
        templates = templatesForShape(selectedShape)
        if let saved = selectedIndexForShape[selectedShape], saved.item < templates.count {
            selectedTemplateIndex = saved
            nextButton.isEnabled = true
            nextButton.backgroundColor = kmainColor
        } else {
            selectedTemplateIndex = nil
            nextButton.isEnabled = false
            nextButton.backgroundColor = UIColor(hexString: "#BFC7D2")
        }
        templatesCollection.reloadData()
    }

    private func templatesForShape(_ shape: StickerSheetShape) -> [StickerSheetTemplate] {
        switch shape {
        case .rectangle:
            return [
                StickerSheetTemplate(id: "rect_6", title: "6 per page", sizeText: "2 × 3", pattern: GridPattern(rows: 3, columns: 2)),
                StickerSheetTemplate(id: "rect_8", title: "8 per page", sizeText: "2 × 4", pattern: GridPattern(rows: 4, columns: 2)),
                StickerSheetTemplate(id: "rect_10", title: "10 per page", sizeText: "2 × 5", pattern: GridPattern(rows: 5, columns: 2)),
                StickerSheetTemplate(id: "rect_14", title: "14 per page", sizeText: "2 × 7", pattern: GridPattern(rows: 7, columns: 2)),
                StickerSheetTemplate(id: "rect_20", title: "20 per page", sizeText: "2 × 10", pattern: GridPattern(rows: 10, columns: 2)),
                StickerSheetTemplate(id: "rect_30", title: "30 per page", sizeText: "3 × 10", pattern: GridPattern(rows: 10, columns: 3)),
                StickerSheetTemplate(id: "rect_60", title: "60 per page", sizeText: "4 × 15", pattern: GridPattern(rows: 15, columns: 4)),
                StickerSheetTemplate(id: "rect_80", title: "80 per page", sizeText: "4 × 20", pattern: GridPattern(rows: 20, columns: 4))
            ]
        case .round:
            return [
                StickerSheetTemplate(id: "round_4", title: "4 per page", sizeText: "2 × 2", pattern: GridPattern(rows: 2, columns: 2)),
                StickerSheetTemplate(id: "round_6", title: "6 per page", sizeText: "2 × 3", pattern: GridPattern(rows: 3, columns: 2)),
                StickerSheetTemplate(id: "round_9", title: "9 per page", sizeText: "3 × 3", pattern: GridPattern(rows: 3, columns: 3)),
                StickerSheetTemplate(id: "round_12", title: "12 per page", sizeText: "3 × 4", pattern: GridPattern(rows: 4, columns: 3)),
                StickerSheetTemplate(id: "round_20", title: "20 per page", sizeText: "4 × 5", pattern: GridPattern(rows: 5, columns: 4)),
                StickerSheetTemplate(id: "round_30", title: "30 per page", sizeText: "5 × 6", pattern: GridPattern(rows: 6, columns: 5)),
                StickerSheetTemplate(id: "round_80", title: "80 per page", sizeText: "8 × 10", pattern: GridPattern(rows: 10, columns: 8))
            ]
        case .oval:
            return [
                StickerSheetTemplate(id: "oval_6", title: "6 per page", sizeText: "3 × 2", pattern: GridPattern(rows: 3, columns: 2)),
                StickerSheetTemplate(id: "oval_8", title: "8 per page", sizeText: "4 × 2", pattern: GridPattern(rows: 4, columns: 2)),
                StickerSheetTemplate(id: "oval_10", title: "10 per page", sizeText: "5 × 2", pattern: GridPattern(rows: 5, columns: 2)),
                StickerSheetTemplate(id: "oval_14", title: "18 per page", sizeText: "6 × 3", pattern: GridPattern(rows: 6, columns: 3)),
                StickerSheetTemplate(id: "oval_20", title: "24 per page", sizeText: "8 × 3", pattern: GridPattern(rows: 8, columns: 3))
            ]
        case .square:
            return [
                StickerSheetTemplate(id: "sq_4", title: "4 per page", sizeText: "2 × 2", pattern: GridPattern(rows: 2, columns: 2)),
                StickerSheetTemplate(id: "sq_6", title: "6 per page", sizeText: "3 × 2", pattern: GridPattern(rows: 3, columns: 2)),
                StickerSheetTemplate(id: "sq_9", title: "9 per page", sizeText: "3 × 3", pattern: GridPattern(rows: 3, columns: 3)),
                StickerSheetTemplate(id: "sq_12", title: "12 per page", sizeText: "4 × 3", pattern: GridPattern(rows: 4, columns: 3)),
                StickerSheetTemplate(id: "sq_20", title: "20 per page", sizeText: "5 × 4", pattern: GridPattern(rows: 5, columns: 4)),
                StickerSheetTemplate(id: "sq_80", title: "80 per page", sizeText: "10 × 8", pattern: GridPattern(rows: 10, columns: 8))
            ]
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoryCollection { return categories.count }
        return templates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoryCollection {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerChipCell.identifier, for: indexPath) as? StickerChipCell else {
                return UICollectionViewCell()
            }
            let shape = categories[indexPath.item]
            cell.configure(title: shape.title, icon: shape.icon, selected: shape == selectedShape)
            return cell
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerTemplateCell.identifier, for: indexPath) as? StickerTemplateCell else {
            return UICollectionViewCell()
        }
        let tpl = templates[indexPath.item]
        cell.configure(
            title: tpl.title,
            size: tpl.sizeText,
            shape: selectedShape,
            pattern: tpl.pattern,
            selected: selectedTemplateIndex == indexPath
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoryCollection {
            let newShape = categories[indexPath.item]
            guard newShape != selectedShape else { return }
            selectedShape = newShape
            categoryCollection.reloadData()
            reloadTemplates()
        } else {
            let prev = selectedTemplateIndex
            selectedTemplateIndex = indexPath
            selectedIndexForShape[selectedShape] = indexPath
            if let p = prev { templatesCollection.reloadItems(at: [p]) }
            templatesCollection.reloadItems(at: [indexPath])
            nextButton.isEnabled = true
            nextButton.backgroundColor = kmainColor
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView == categoryCollection {
            let title = categories[indexPath.item].title
            let font = kmiddleFont(fontSize: 13)
            let paddingH: CGFloat = 24
            let height: CGFloat = 30
            let textWidth = (title as NSString).boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: height),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            ).width
            let iconWidth: CGFloat = 16
            let spacing: CGFloat = 6
            let minWidth: CGFloat = 92
            let width = max(minWidth, ceil(textWidth) + paddingH + iconWidth + spacing)
            return CGSize(width: width, height: height)
        }
        let totalInset: CGFloat = 16 + 16
        let spacing: CGFloat = 12
        let available = view.bounds.width - totalInset - spacing
        let width = floor(available / 2)
        return CGSize(width: width, height: width * 1.54)
    }
}

// MARK: - 相册 → 裁剪 → 网格预览

extension StickerViewController: PHPickerViewControllerDelegate {

    private func selectImage(template: StickerSheetTemplate) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
        objc_setAssociatedObject(picker, &PickerTemplateKey.holder, template, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        let template = objc_getAssociatedObject(picker, &PickerTemplateKey.holder) as? StickerSheetTemplate
        guard let tpl = template else { return }

        let itemProvider = result.itemProvider
        guard itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            DispatchQueue.main.async {
                guard let self, let uiImage = image as? UIImage else { return }
                self.handleSelectedImage(uiImage, template: tpl)
            }
        }
    }

    private func handleSelectedImage(_ image: UIImage, template: StickerSheetTemplate) {
        var clipRatio: ZLImageClipRatio = .wh1x1
        if selectedShape == .round {
            clipRatio = .circle
        } else if selectedShape == .oval || selectedShape == .rectangle {
            clipRatio = .wh4x3
        }

        ZLImageEditorConfiguration.default()
            .editImageTools([.clip])
            .clipRatios([clipRatio])
            .showClipDirectlyIfOnlyHasClipTool(true)
            .adjustTools([.brightness, .contrast, .saturation])

        ZLImageEditorUIConfiguration.default().editDoneBtnBgColor = kmainColor
        ZLImageEditorUIConfiguration.default().adjustSliderTintColor = kmainColor

        let editor = ZLEditImageViewController(image: image)
        editor.editFinishBlock = { [weak self] editedImage, _ in
            guard let self else { return }
            var out = editedImage
            if self.selectedShape == .round {
                out = self.makeOvalImage(from: editedImage, ratio: CGSize(width: 1, height: 1)) ?? editedImage
            } else if self.selectedShape == .oval {
                out = self.makeOvalImage(from: editedImage, ratio: CGSize(width: 4, height: 3)) ?? editedImage
            }
            let layoutKind = (self.selectedShape == .rectangle || self.selectedShape == .oval) ? 1 : 0
            let vc = StickerGridPreviewViewController()
            vc.sourceImage = out
            vc.pattern = template.pattern
            vc.layoutKind = layoutKind
            self.pushController(vc)
        }
        editor.modalPresentationStyle = .fullScreen
        present(editor, animated: true)
    }

    private func makeOvalImage(from image: UIImage, ratio: CGSize) -> UIImage? {
        guard ratio.width > 0, ratio.height > 0 else { return nil }

        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let imageRatio = imageWidth / imageHeight
        let targetRatio = ratio.width / ratio.height

        let cropRect: CGRect
        if imageRatio > targetRatio {
            let newWidth = imageHeight * targetRatio
            let x = (imageWidth - newWidth) / 2
            cropRect = CGRect(x: x, y: 0, width: newWidth, height: imageHeight)
        } else {
            let newHeight = imageWidth / targetRatio
            let y = (imageHeight - newHeight) / 2
            cropRect = CGRect(x: 0, y: y, width: imageWidth, height: newHeight)
        }

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return nil }
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        let targetSize = CGSize(width: croppedImage.size.width, height: croppedImage.size.height)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        let ovalRect = CGRect(origin: .zero, size: targetSize)
        ctx.addEllipse(in: ovalRect)
        ctx.clip()
        croppedImage.draw(in: ovalRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

private struct PickerTemplateKey {
    static var holder: UInt8 = 0
}

// MARK: - Cells

private final class StickerChipCell: UICollectionViewCell {
    static let identifier = "StickerChipCell"

    private let container = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

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
        container.layer.cornerRadius = 15
        container.layer.masksToBounds = true
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(hexString: "#D9DBE1")?.cgColor
        container.backgroundColor = .white

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIColor(hexString: "#1D212C")

        titleLabel.font = kmiddleFont(fontSize: 13)
        titleLabel.textColor = UIColor(hexString: "#1D212C")
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1

        contentView.addSubview(container)
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(6)
        }
    }

    func configure(title: String, icon: UIImage?, selected: Bool) {
        titleLabel.text = title
        iconView.image = icon
        if selected {
            container.backgroundColor = kmainColor
            container.layer.borderColor = kmainColor.cgColor
            titleLabel.textColor = .white
            iconView.tintColor = .white
        } else {
            container.backgroundColor = .white
            container.layer.borderColor = UIColor(hexString: "#D9DBE1")?.cgColor
            titleLabel.textColor = UIColor(hexString: "#1D212C")
            iconView.tintColor = UIColor(hexString: "#1D212C")
        }
    }
}

private final class StickerTemplateCell: UICollectionViewCell {
    static let identifier = "StickerTemplateCell"

    private let container = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let sizeLabel = UILabel()
    private let radioOuter = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .clear
        container.backgroundColor = .white
        container.layer.cornerRadius = 20
        container.layer.masksToBounds = true
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(hexString: "#D9DBE1")?.cgColor

        imageView.contentMode = .scaleAspectFit
        titleLabel.font = kboldFont(fontSize: 15)
        titleLabel.textColor = UIColor(hexString: "#1D212C")
        sizeLabel.font = kmiddleFont(fontSize: 12)
        sizeLabel.textColor = UIColor(hexString: "#78818D")
        titleLabel.textAlignment = .center
        sizeLabel.textAlignment = .center

        contentView.addSubview(container)
        container.addSubview(imageView)
        container.addSubview(titleLabel)
        container.addSubview(sizeLabel)
        container.addSubview(radioOuter)

        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalToSuperview().multipliedBy(0.55)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
        }
        sizeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerX.equalToSuperview()
        }
        radioOuter.snp.makeConstraints { make in
            make.top.equalTo(sizeLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(12)
            make.width.height.equalTo(24)
        }
    }

    func configure(title: String, size: String, shape: StickerSheetShape, pattern: GridPattern, selected: Bool) {
        titleLabel.text = title
        sizeLabel.text = size
        imageView.image = StickerTemplatePreviewRenderer.previewImage(shape: shape, pattern: pattern)
        container.layer.borderColor = (selected ? kmainColor : UIColor(hexString: "#D9DBE1"))?.cgColor
        let sym = selected ? "checkmark.circle.fill" : "circle"
        radioOuter.image = UIImage(systemName: sym)?.withTintColor(selected ? kmainColor : UIColor(hexString: "#78818D") ?? .gray, renderingMode: .alwaysOriginal)
    }
}
