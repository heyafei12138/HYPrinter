//
//  StickerGridPreviewViewController.swift
//  HYPrinter
//

import UIKit

/// 按网格平铺预览并打印（对照 LabelsPreviewVC）
final class StickerGridPreviewViewController: BaseViewController {

    var sourceImage: UIImage!
    var pattern: GridPattern = GridPattern(rows: 10, columns: 20)
    /// 0: 方形格（圆/方） 1: 矩形格（矩形/椭圆裁切后）
    var layoutKind: Int = 0

    private let canvasCard = UIView()
    private let gridContainer = UIView()
    private var gridImageViews: [UIImageView] = []
    private let printButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "printer_action"), for: .normal)
        return button
    }()
    override func buildSubviews() {
        super.buildSubviews()
        title = "预览"
        view.backgroundColor = UIColor(hexString: "#EEF2F7")

        canvasCard.backgroundColor = .white
        canvasCard.layer.cornerRadius = 12
        canvasCard.layer.masksToBounds = true

        view.addSubview(canvasCard)
        canvasCard.addSubview(gridContainer)

        canvasCard.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(canvasCard.snp.width).multipliedBy(1.4)
        }

        gridContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(pattern.contentInsets)
        }

        topBar.addSubview(printButton)
       
        
        printButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(10)
            make.width.height.equalTo(24)
        }
        printButton.addTarget(self, action: #selector(printCanvasCard), for: .touchUpInside)
        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if gridImageViews.isEmpty, gridContainer.bounds.width > 0 {
            buildGrid()
        }
    }

    private func buildGrid() {
        gridImageViews.forEach { $0.removeFromSuperview() }
        gridImageViews.removeAll()

        let rows = pattern.rows
        let cols = pattern.columns
        let spacing = pattern.spacing

        gridContainer.layoutIfNeeded()

        let containerWidth = gridContainer.bounds.width
        let containerHeight = gridContainer.bounds.height

        var cellWidth: CGFloat = 0
        var cellHeight: CGFloat = 0

        switch layoutKind {
        case 0:
            let rawWidth = (containerWidth - CGFloat(cols - 1) * spacing) / CGFloat(cols)
            let rawHeight = (containerHeight - CGFloat(rows - 1) * spacing) / CGFloat(rows)
            let side = min(rawWidth, rawHeight)
            cellWidth = side
            cellHeight = side
        case 1:
            let maxCellWidth = (containerWidth - CGFloat(cols - 1) * spacing) / CGFloat(cols)
            let maxCellHeight = (containerHeight - CGFloat(rows - 1) * spacing) / CGFloat(rows)
            let rawHeight = maxCellWidth * 3 / 4
            if rawHeight <= maxCellHeight {
                cellWidth = maxCellWidth
                cellHeight = rawHeight
            } else {
                cellHeight = maxCellHeight
                cellWidth = cellHeight * 4 / 3
            }
        default:
            break
        }

        let gridWidth = CGFloat(cols) * cellWidth + CGFloat(cols - 1) * spacing
        let gridHeight = CGFloat(rows) * cellHeight + CGFloat(rows - 1) * spacing

        let offsetX = (containerWidth - gridWidth) / 2
        let offsetY = (containerHeight - gridHeight) / 2

        for r in 0..<rows {
            for c in 0..<cols {
                let iv = UIImageView()
                iv.contentMode = .scaleAspectFill
                iv.clipsToBounds = true
                iv.image = sourceImage

                gridContainer.addSubview(iv)
                gridImageViews.append(iv)

                let x = offsetX + CGFloat(c) * (cellWidth + spacing)
                let y = offsetY + CGFloat(r) * (cellHeight + spacing)

                iv.snp.makeConstraints { make in
                    make.left.equalToSuperview().offset(x)
                    make.top.equalToSuperview().offset(y)
                    make.width.equalTo(cellWidth)
                    make.height.equalTo(cellHeight)
                }
            }
        }
    }

    @objc private func printCanvasCard() {
        let renderer = UIGraphicsImageRenderer(bounds: canvasCard.bounds)
        let image = renderer.image { ctx in
            canvasCard.layer.render(in: ctx.cgContext)
        }

        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = appName
        printInfo.outputType = .photo
        printController.printInfo = printInfo
        printController.printingItem = image
        printController.present(animated: true, completionHandler: nil)
    }
}
