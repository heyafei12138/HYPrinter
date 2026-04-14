//
//  PrintHistoryStore.swift
//  HYPrinter
//

import UIKit

extension Notification.Name {
    static let printHistoryDidChange = Notification.Name("printHistoryDidChange")
}

/// 打印来源分类（用于历史列表分组）
enum PrintHistoryCategory: String, Codable, CaseIterable, Comparable {
    case image
    case document
    case sticker
    case text
    case web
    case contact

    var displayTitle: String {
        switch self {
        case .image: return "图片"
        case .document: return "文档"
        case .sticker: return "贴纸"
        case .text: return "文本"
        case .web: return "网页"
        case .contact: return "联系人"
        }
    }

    static func < (lhs: PrintHistoryCategory, rhs: PrintHistoryCategory) -> Bool {
        lhs.sortIndex < rhs.sortIndex
    }

    private var sortIndex: Int {
        switch self {
        case .image: return 0
        case .document: return 1
        case .sticker: return 2
        case .text: return 3
        case .web: return 4
        case .contact: return 5
        }
    }
}

/// 一条打印历史记录（资源保存在沙盒 PrintHistory/{id}/ 下）
struct PrintHistoryRecord: Codable, Equatable {
    let id: String
    let category: PrintHistoryCategory
    let title: String
    let subtitle: String?
    let createdAt: TimeInterval
    /// 相对于 `PrintHistory/{id}/` 的文件名
    let fileNames: [String]
}

/// 打印历史持久化（JSON 索引 + 按记录分目录存文件）
final class PrintHistoryStore {

    static let shared = PrintHistoryStore()

    private let lock = NSLock()
    private let maxRecords = 200
    private let folderName = "PrintHistory"
    private let indexFileName = "index.json"

    private var documentsRoot: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var historyRoot: URL {
        documentsRoot.appendingPathComponent(folderName, isDirectory: true)
    }

    private var indexURL: URL {
        historyRoot.appendingPathComponent(indexFileName)
    }

    private init() {
        try? FileManager.default.createDirectory(at: historyRoot, withIntermediateDirectories: true)
    }

    // MARK: - Read

    func allRecordsSorted() -> [PrintHistoryRecord] {
        lock.lock()
        defer { lock.unlock() }
        return loadIndex().sorted { $0.createdAt > $1.createdAt }
    }

    func recordsGroupedByCategory() -> [(category: PrintHistoryCategory, records: [PrintHistoryRecord])] {
        let all = allRecordsSorted()
        var map: [PrintHistoryCategory: [PrintHistoryRecord]] = [:]
        for r in all {
            map[r.category, default: []].append(r)
        }
        return PrintHistoryCategory.allCases.compactMap { cat in
            guard let list = map[cat], !list.isEmpty else { return nil }
            return (cat, list.sorted { $0.createdAt > $1.createdAt })
        }
    }

    func recordDirectoryURL(for id: String) -> URL {
        historyRoot.appendingPathComponent(id, isDirectory: true)
    }

    func fileURLs(for record: PrintHistoryRecord) -> [URL] {
        let base = recordDirectoryURL(for: record.id)
        return record.fileNames.map { base.appendingPathComponent($0) }
    }

    // MARK: - Write

    /// 保存图片类打印（相册多图、贴纸单图等）
    func saveImageCategoryPrint(
        images: [UIImage],
        category: PrintHistoryCategory,
        title: String,
        subtitle: String?
    ) throws -> PrintHistoryRecord {
        guard !images.isEmpty else {
            throw NSError(domain: "PrintHistory", code: 1, userInfo: [NSLocalizedDescriptionKey: "无图片"])
        }
        let id = UUID().uuidString
        let dir = recordDirectoryURL(for: id)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var names: [String] = []
        for (i, img) in images.enumerated() {
            let name = "\(i).jpg"
            let url = dir.appendingPathComponent(name)
            guard let data = img.jpegData(compressionQuality: 0.88) else { continue }
            try data.write(to: url, options: .atomic)
            names.append(name)
        }
        guard !names.isEmpty else {
            throw NSError(domain: "PrintHistory", code: 2, userInfo: [NSLocalizedDescriptionKey: "写入失败"])
        }
        let record = PrintHistoryRecord(
            id: id,
            category: category,
            title: title,
            subtitle: subtitle,
            createdAt: Date().timeIntervalSince1970,
            fileNames: names
        )
        try appendRecord(record)
        return record
    }

    func saveImagePrint(images: [UIImage], title: String, subtitle: String?) throws -> PrintHistoryRecord {
        try saveImageCategoryPrint(images: images, category: .image, title: title, subtitle: subtitle)
    }

    /// 保存单文件类打印（PDF / 图片 / Office 等），会复制到历史目录
    func saveFilePrint(
        category: PrintHistoryCategory,
        title: String,
        subtitle: String?,
        copyingFileAt sourceURL: URL
    ) throws -> PrintHistoryRecord {
        let id = UUID().uuidString
        let dir = recordDirectoryURL(for: id)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let ext = sourceURL.pathExtension.lowercased()
        let destName: String
        if ext.isEmpty {
            destName = "print.data"
        } else if ["jpg", "jpeg", "png", "heic", "gif", "webp", "pdf", "txt"].contains(ext) {
            destName = "print.\(ext)"
        } else {
            destName = "print.\(ext)"
        }
        let dest = dir.appendingPathComponent(destName)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: sourceURL, to: dest)

        let record = PrintHistoryRecord(
            id: id,
            category: category,
            title: title,
            subtitle: subtitle,
            createdAt: Date().timeIntervalSince1970,
            fileNames: [destName]
        )
        try appendRecord(record)
        return record
    }

    func deleteRecord(id: String) throws {
        lock.lock()
        defer { lock.unlock() }
        var list = loadIndex()
        list.removeAll { $0.id == id }
        try saveIndex(list)
        let dir = recordDirectoryURL(for: id)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .printHistoryDidChange, object: nil)
        }
    }

    // MARK: - Private

    private func loadIndex() -> [PrintHistoryRecord] {
        guard FileManager.default.fileExists(atPath: indexURL.path),
              let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([PrintHistoryRecord].self, from: data) else {
            return []
        }
        return decoded
    }

    private func saveIndex(_ records: [PrintHistoryRecord]) throws {
        let data = try JSONEncoder().encode(records)
        try data.write(to: indexURL, options: .atomic)
    }

    private func appendRecord(_ record: PrintHistoryRecord) throws {
        lock.lock()
        defer { lock.unlock() }
        var list = loadIndex()
        list.insert(record, at: 0)
        if list.count > maxRecords {
            let overflow = list.suffix(from: maxRecords)
            for old in overflow {
                let dir = recordDirectoryURL(for: old.id)
                try? FileManager.default.removeItem(at: dir)
            }
            list = Array(list.prefix(maxRecords))
        }
        try saveIndex(list)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .printHistoryDidChange, object: nil)
        }
    }
}

// MARK: - UI 辅助

enum PrintHistoryIconProvider {

    static func rowIcon(for record: PrintHistoryRecord) -> UIImage? {
        if let first = record.fileNames.first {
            let ext = (first as NSString).pathExtension.lowercased()
            switch ext {
            case "pdf":
                return UIImage(systemName: "doc.fill")?.withTintColor(UIColor(hexString: "#E53935") ?? .red, renderingMode: .alwaysOriginal)
            case "jpg", "jpeg", "png", "heic", "gif", "webp":
                return UIImage(systemName: "photo.fill")?.withTintColor(kmainColor, renderingMode: .alwaysOriginal)
            case "txt", "md", "csv":
                return UIImage(systemName: "doc.plaintext.fill")?.withTintColor(UIColor(hexString: "#5B6472") ?? .gray, renderingMode: .alwaysOriginal)
            default:
                return UIImage(systemName: "doc.richtext")?.withTintColor(UIColor(hexString: "#2F80ED") ?? .blue, renderingMode: .alwaysOriginal)
            }
        }
        return categorySymbol(record.category)
    }

    static func categorySymbol(_ category: PrintHistoryCategory) -> UIImage? {
        let name: String
        switch category {
        case .image: name = "photo.on.rectangle.angled"
        case .document: name = "doc.text"
        case .sticker: name = "square.grid.3x3.fill"
        case .text: name = "text.alignleft"
        case .web: name = "globe"
        case .contact: name = "person.crop.rectangle.stack"
        }
        return UIImage(systemName: name)?.withTintColor(kmainColor, renderingMode: .alwaysOriginal)
    }
}
