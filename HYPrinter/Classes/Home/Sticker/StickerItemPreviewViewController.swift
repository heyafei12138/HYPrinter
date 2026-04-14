//
//  StickerItemPreviewViewController.swift
//  HYPrinter
//

import UIKit

/// 单张贴纸放大预览，下一步进入网格（对照 LabelsDetailVC）
final class StickerItemPreviewViewController: BaseViewController {

    var item: StickerItem!
    var gridPattern: GridPattern = GridPattern(rows: 3, columns: 2)

    private let imageView = UIImageView()
    private let nextButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("下一步", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = kboldFont(fontSize: 17)
        b.backgroundColor = kmainColor
        b.layer.cornerRadius = 24
        return b
    }()

    override func buildSubviews() {
        super.buildSubviews()
        title = "预览"

        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(kScreenWidth - 32)
        }

        loadItemImage()

        view.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(48)
        }
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
    }

    private func loadItemImage() {
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

    @objc private func handleNext() {
        let preview = StickerGridPreviewViewController()
        preview.sourceImage = imageView.image ?? UIImage()
        preview.pattern = gridPattern
        pushController(preview)
    }
}
