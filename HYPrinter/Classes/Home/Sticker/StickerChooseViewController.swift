//
//  StickerChooseViewController.swift
//  HYPrinter
//

import UIKit

/// 贴纸库 / 相册 选择（对照 LabelsChooseVC）
final class StickerChooseViewController: BaseViewController {

    enum Choice {
        case stickerLibrary
        case photoLibrary
    }

    var onChoose: ((Choice) -> Void)?

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        return v
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .custom)
        let img = UIImage(systemName: "xmark.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 22, weight: .medium))
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [.secondaryLabel, .systemGray5]))
        b.setImage(img, for: .normal)
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Choose Type"
        l.textAlignment = .center
        l.textColor = UIColor(hexString: "#1A1F27")
        l.font = kboldFont(fontSize: 17)
        return l
    }()

    private let stickerCard = StickerChooseCardView(title: "Sticker Library", imageName: "ic_photo_stick")
    private let photoCard = StickerChooseCardView(title: "Photos", imageName: "ic_photo_img")

    private let cardsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .fill
        s.spacing = 16
        s.distribution = .fillEqually
        return s
    }()

    override var shouldHideNavigationBar: Bool {
        get { true }
        set { }
    }

    override func buildSubviews() {
        super.buildSubviews()
        view.backgroundColor = .clear
        view.addSubview(dimView)
        view.addSubview(contentView)

        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(247)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(closeAction))
        dimView.addGestureRecognizer(tap)

        contentView.addSubview(closeButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(cardsStack)

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.centerX.equalToSuperview()
        }

        cardsStack.addArrangedSubview(stickerCard)
        cardsStack.addArrangedSubview(photoCard)

        cardsStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(32)
            make.height.greaterThanOrEqualTo(113)
        }

        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)

        stickerCard.onTapped = { [weak self] in
            guard let self else { return }
            self.dismiss(animated: false) {
                self.onChoose?(.stickerLibrary)
            }
        }
        photoCard.onTapped = { [weak self] in
            guard let self else { return }
            self.dismiss(animated: true) {
                self.onChoose?(.photoLibrary)
            }
        }
    }

    @objc private func closeAction() {
        dismiss(animated: true)
    }
}

// MARK: - Card

private final class StickerChooseCardView: UIView {
    var onTapped: (() -> Void)?

    private let container = UIView()
    private let iconWrapper = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    init(title: String, imageName: String) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        titleLabel.text = title
        iconView.image = UIImage(named: imageName) ?? UIImage(systemName: "photo")
        iconView.tintColor = UIColor(hexString: "#1A1F27")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        container.backgroundColor = UIColor(hexString: "#F5F5F5")
        container.layer.cornerRadius = 20
        container.layer.masksToBounds = true

        iconWrapper.layer.cornerRadius = 12
        iconWrapper.layer.masksToBounds = true

        iconView.contentMode = .scaleAspectFit

        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(hexString: "#1A1F27")
        titleLabel.font = kmiddleFont(fontSize: 14)

        addSubview(container)
        container.addSubview(iconWrapper)
        iconWrapper.addSubview(iconView)
        container.addSubview(titleLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        container.addGestureRecognizer(tap)
    }

    private func setupConstraints() {
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        iconWrapper.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(52)
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(44)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconWrapper.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
    }

    @objc private func handleTap() {
        onTapped?()
    }
}
