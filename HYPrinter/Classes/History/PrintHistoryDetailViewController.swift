//
//  PrintHistoryDetailViewController.swift
//  HYPrinter
//

import PDFKit
import UIKit

/// 打印历史详情：全屏预览文件 / 图片，右上角再次打印
final class PrintHistoryDetailViewController: BaseViewController {

    private let record: PrintHistoryRecord
    private var pdfView: PDFView?
    private var imageScrollView: UIScrollView?
    private let printButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "printer_action"), for: .normal)
        return button
    }()
    init(record: PrintHistoryRecord) {
        self.record = record
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func buildSubviews() {
        super.buildSubviews()
        topBar.barTitle = "详情"
        
        topBar.addSubview(printButton)
        
        printButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(10)
            make.width.height.equalTo(24)
        }
        printButton.addTarget(self, action: #selector(handleReprint), for: .touchUpInside)

        buildPreview()
    }

    /// 列表等位置展示的时间文案（详情页不再展示元信息，仅保留工具方法）
    static func displayDateString(for ts: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: ts)
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: date)
    }

    private func buildPreview() {
        let urls = PrintHistoryStore.shared.fileURLs(for: record).filter { FileManager.default.fileExists(atPath: $0.path) }
        guard let first = urls.first else {
            view.backgroundColor = UIColor(hexString: "#0B0B0C") ?? .black
            let empty = UILabel()
            empty.text = "文件已删除或不可用"
            empty.textColor = UIColor(hexString: "#9AA4B2")
            empty.font = kmiddleFont(fontSize: 15)
            empty.textAlignment = .center
            view.addSubview(empty)
            empty.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(32)
                make.top.greaterThanOrEqualTo(topBar.snp.bottom).offset(24)
            }
            return
        }

        let ext = first.pathExtension.lowercased()

        if ext == "pdf", let doc = PDFDocument(url: first) {
            view.backgroundColor = .white
            let pv = PDFView()
            pv.document = doc
            pv.autoScales = true
            pv.displayDirection = .vertical
            pv.displayMode = .singlePageContinuous
            pv.backgroundColor = .white
            view.addSubview(pv)
            pv.snp.makeConstraints { make in
                make.top.equalTo(topBar.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            pdfView = pv
            return
        }

        if ["jpg", "jpeg", "png", "heic", "gif", "webp"].contains(ext) {
            view.backgroundColor = UIColor(hexString: "#0B0B0C") ?? .black
            let sc = UIScrollView()
            sc.alwaysBounceVertical = true
            sc.showsVerticalScrollIndicator = true
            sc.backgroundColor = .clear
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 0
            stack.alignment = .fill

            for url in urls {
                let e = url.pathExtension.lowercased()
                guard ["jpg", "jpeg", "png", "heic", "gif", "webp"].contains(e) else { continue }
                guard let img = UIImage(contentsOfFile: url.path) else { continue }
                let iv = UIImageView(image: img)
                iv.contentMode = .scaleAspectFit
                iv.backgroundColor = .clear
                stack.addArrangedSubview(iv)
            }

            sc.addSubview(stack)
            view.addSubview(sc)
            sc.snp.makeConstraints { make in
                make.top.equalTo(topBar.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            stack.snp.makeConstraints { make in
                make.edges.equalTo(sc.contentLayoutGuide)
                make.width.equalTo(sc.frameLayoutGuide)
            }
            imageScrollView = sc
            return
        }

        view.backgroundColor = UIColor(hexString: "#0B0B0C") ?? .black
        let hint = UILabel()
        hint.text = "无法预览此格式\n\(first.lastPathComponent)"
        hint.numberOfLines = 0
        hint.textAlignment = .center
        hint.font = kmiddleFont(fontSize: 14)
        hint.textColor = UIColor(hexString: "#9AA4B2")
        view.addSubview(hint)
        hint.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.greaterThanOrEqualTo(topBar.snp.bottom).offset(24)
        }
    }

    @objc private func handleReprint() {
        let urls = PrintHistoryStore.shared.fileURLs(for: record).filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !urls.isEmpty else {
            let alert = UIAlertController(title: "无法打印", message: "找不到已保存的文件。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .default))
            present(alert, animated: true)
            return
        }

        let printController = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.jobName = record.title
        info.outputType = record.category == .image || record.category == .sticker ? .photo : .general
        printController.printInfo = info

        let imageURLs = urls.filter { ["jpg", "jpeg", "png", "heic", "gif", "webp"].contains($0.pathExtension.lowercased()) }
        if imageURLs.count == urls.count, !imageURLs.isEmpty {
            let images = imageURLs.compactMap { UIImage(contentsOfFile: $0.path) }
            guard !images.isEmpty else { return }
            printController.printingItems = images
        } else if urls.count == 1 {
            printController.printingItem = urls[0]
        } else {
            printController.printingItems = urls
        }

        printController.present(animated: true, completionHandler: nil)
    }
}
