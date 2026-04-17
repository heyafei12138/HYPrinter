//
//  StickerModels.swift
//  HYPrinter
//

import UIKit

// MARK: - Grid

struct GridPattern: Hashable {
    let rows: Int
    let columns: Int
    let spacing: CGFloat
    let contentInsets: UIEdgeInsets

    init(
        rows: Int,
        columns: Int,
        spacing: CGFloat = 16,
        contentInsets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    ) {
        self.rows = max(1, rows)
        self.columns = max(1, columns)
        self.spacing = spacing
        self.contentInsets = contentInsets
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rows)
        hasher.combine(columns)
        hasher.combine(spacing)
        hasher.combine(contentInsets.top)
        hasher.combine(contentInsets.left)
        hasher.combine(contentInsets.bottom)
        hasher.combine(contentInsets.right)
    }

    static func == (lhs: GridPattern, rhs: GridPattern) -> Bool {
        lhs.rows == rhs.rows &&
            lhs.columns == rhs.columns &&
            lhs.spacing == rhs.spacing &&
            lhs.contentInsets.top == rhs.contentInsets.top &&
            lhs.contentInsets.left == rhs.contentInsets.left &&
            lhs.contentInsets.bottom == rhs.contentInsets.bottom &&
            lhs.contentInsets.right == rhs.contentInsets.right
    }
}

// MARK: - Sheet shape & templates

enum StickerSheetShape: CaseIterable {
    case rectangle
    case round
    case oval
    case square

    var title: String {
        switch self {
        case .rectangle: return "Rectangle"
        case .round: return "Round"
        case .oval: return "Oval"
        case .square: return "Square"
        }
    }

    var icon: UIImage? { StickerCategoryIconRenderer.icon(for: self) }
}

struct StickerSheetTemplate: Hashable {
    let id: String
    let title: String
    let sizeText: String
    let pattern: GridPattern
}

// MARK: - 模板 cell 示例图（按形状 + 行列绘制）

enum StickerTemplatePreviewRenderer {

    private static let cache = NSCache<NSString, UIImage>()

    /// 生成与当前模板行列、形状一致的示意缩略图（带简单缓存）
    static func previewImage(shape: StickerSheetShape, pattern: GridPattern, size: CGSize = CGSize(width: 160, height: 160)) -> UIImage {
        let rows = pattern.rows
        let cols = pattern.columns
        let key = "\(shapeTitle(shape))_\(rows)x\(cols)_\(Int(size.width))x\(Int(size.height))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let image = render(shape: shape, rows: rows, columns: cols, size: size)
        cache.setObject(image, forKey: key)
        return image
    }

    private static func shapeTitle(_ shape: StickerSheetShape) -> String {
        switch shape {
        case .rectangle: return "rect"
        case .round: return "round"
        case .oval: return "oval"
        case .square: return "square"
        }
    }

    private static func render(shape: StickerSheetShape, rows: Int, columns: Int, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let sheetRect = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
            let sheetPath = UIBezierPath(roundedRect: sheetRect, cornerRadius: size.width * 0.08)
            kBgColor.setFill()
            sheetPath.fill()
            UIColor(hexString: "#D9DBE1")?.setStroke()
            sheetPath.lineWidth = 1
            sheetPath.stroke()

            let inner = sheetRect.insetBy(dx: 6, dy: 6)
            let rows = max(1, rows)
            let columns = max(1, columns)
            let gap = max(0.5, min(2.5, min(inner.width, inner.height) / CGFloat(max(rows, columns) * 6)))

            let totalGapW = gap * CGFloat(columns - 1)
            let totalGapH = gap * CGFloat(rows - 1)
            let cellW = (inner.width - totalGapW) / CGFloat(columns)
            let cellH = (inner.height - totalGapH) / CGFloat(rows)

            let strokeColor = kmainColor.withAlphaComponent(0.5)
            let fillColor = strokeColor.withAlphaComponent(0.14)

            for r in 0..<rows {
                for c in 0..<columns {
                    let x = inner.minX + CGFloat(c) * (cellW + gap)
                    let y = inner.minY + CGFloat(r) * (cellH + gap)
                    let cell = CGRect(x: x, y: y, width: cellW, height: cellH).insetBy(dx: 0.35, dy: 0.35)
                    drawShape(shape, in: cell, context: cg, fill: fillColor, stroke: strokeColor)
                }
            }
        }
    }

    private static func drawShape(
        _ shape: StickerSheetShape,
        in cell: CGRect,
        context cg: CGContext,
        fill: UIColor,
        stroke: UIColor
    ) {
        cg.saveGState()
        defer { cg.restoreGState() }

        let path: UIBezierPath
        switch shape {
        case .rectangle:
            let w = cell.width * 0.92
            let h = min(cell.height * 0.62, w * 0.55)
            let r = CGRect(x: cell.midX - w / 2, y: cell.midY - h / 2, width: w, height: h)
            path = UIBezierPath(roundedRect: r, cornerRadius: max(1.5, min(w, h) * 0.12))
        case .square:
            let side = min(cell.width, cell.height) * 0.78
            let r = CGRect(x: cell.midX - side / 2, y: cell.midY - side / 2, width: side, height: side)
            path = UIBezierPath(roundedRect: r, cornerRadius: max(1.5, side * 0.1))
        case .round:
            let d = min(cell.width, cell.height) * 0.82
            path = UIBezierPath(ovalIn: CGRect(x: cell.midX - d / 2, y: cell.midY - d / 2, width: d, height: d))
        case .oval:
            let w = cell.width * 0.9
            let h = min(cell.height * 0.72, w * 0.62)
            path = UIBezierPath(ovalIn: CGRect(x: cell.midX - w / 2, y: cell.midY - h / 2, width: w, height: h))
        }

        fill.setFill()
        path.fill()
        stroke.setStroke()
        path.lineWidth = max(0.8, min(cell.width, cell.height) * 0.06)
        path.stroke()
    }
}

// MARK: - Library models

struct StickerCategory {
    let id: String
    let title: String
    var items: [StickerItem]
}

struct StickerItem {
    enum Source {
        case named(String)
        case fileURL(URL)
    }

    let id: String
    let source: Source
    let name: String?
}

// MARK: - Local demo data（资源不足时用工程内已有图片轮转占位）

enum StickerLocalDataSource {
    private static let placeholderImageNames: [String] = [
        "label_home_icon",
        "home_cat_ic",
        "home_cat_ic2",
        "home_cat_icLeft",
        "text_home_icon",
        "web_home_icon",
        "contact_home_icon",
        "email_home_icon",
        "icloud_home_icon",
        "ic_photo_edit"
    ]
    static let AllImageNames: [[String]] = [
        ["jieri1","jieri2","jieri3","jieri4","jieri5","jieri6","jieri7","jieri8"],
        
        ["happy1","happy2","happy3","happy4","happy5","happy6","happy7"],
        ["birthday1","birthday2","birthday3","birthday4","birthday5","birthday6",],

        ["bear1","bear2","bear3","bear4","bear5","bear6","bear7","bear8"],
        ["cat1","cat2","cat3","cat4","cat5","cat6","cat7","cat8"],
        ["bangong1","bangong2","bangong3","bangong4","bangong5","bangong6","bangong7","bangong8"],
        
    ]
    static func loadCategories() -> [StickerCategory] {
        let titles = ["Holiday", "Mood", "Birthday", "Cute", "Animals", "Office"]
        return titles.enumerated().map { index, title in
            let items: [StickerItem] = (0..<AllImageNames[index].count).map { i in
                let name = AllImageNames[index][i]
                return StickerItem(
                    id: "\(index)_\(i)",
                    source: .named(name),
                    name: title
                )
            }
            return StickerCategory(id: "cat_\(index)", title: title, items: items)
        }
    }

    static func loadItems(in dirURL: URL) -> [StickerItem] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return []
        }
        let allowedExts = ["png", "jpg", "jpeg", "webp"]
        var items: [StickerItem] = []
        for fileURL in files where allowedExts.contains(fileURL.pathExtension.lowercased()) {
            let id = fileURL.deletingPathExtension().lastPathComponent
            items.append(StickerItem(id: id, source: .fileURL(fileURL), name: id))
        }
        return items
    }
}

// MARK: - Shape icon (模板条)

enum StickerCategoryIconRenderer {
    static func icon(for shape: StickerSheetShape) -> UIImage? {
        let size = CGSize(width: 16, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path: UIBezierPath
            switch shape {
            case .rectangle:
                path = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 3), cornerRadius: 3)
            case .round:
                path = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
            case .oval:
                path = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 4), cornerRadius: 8)
            case .square:
                path = UIBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerRadius: 2)
            }
            (UIColor(hexString: "#1D212C") ?? .black).setStroke()
            path.lineWidth = 1.5
            path.stroke()
        }
        return img.withRenderingMode(.alwaysTemplate)
    }
}
