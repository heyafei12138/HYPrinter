//
//  GreetingCardModels.swift
//  HYPrinter
//
//  素材卡片模型与本地数据（对照 iOS_Print-dev GreetingCards）
//

import UIKit

struct CardItem: Equatable {
    enum Source: Equatable {
        case named(String)
        case fileURL(URL)
    }

    let id: String
    let source: Source
    let title: String?
}

struct CardCategory: Equatable {
    let id: String
    let title: String
    var items: [CardItem]
}

/// 将「日历」分类下多页模板展开为 12 张内页（与参考工程命名规则一致，资源缺失时走占位图）
enum GreetingCardDetailItemsBuilder {
    static func detailItems(selected item: CardItem, category: CardCategory) -> [CardItem] {
        guard category.id == "calendars" else { return [item] }
        guard let group = calendarAssetGroup(for: item.id) else { return [item] }
        return (1...12).map { idx in
            let num = String(format: "%02d", idx)
            let name = "ic_calendars_card2_\(group)_\(num)"
            return CardItem(id: item.id, source: .named(name), title: nil)
        }
    }

    private static func calendarAssetGroup(for itemId: String) -> Int? {
        switch itemId {
        case "cdemo_15": return 1
        case "cdemo_16": return 2
        case "cdemo_17": return 3
        case "cdemo_18": return 4
        case "cdemo_19": return 5
        case "cdemo_20": return 6
        case "cdemo_21": return 7
        case "cdemo_22": return 8
        case "cdemo_23": return 9
        default: return nil
        }
    }
}

enum GreetingCardDataLoader {
    /// 使用工程内已有图片资源；若后续从参考工程拷贝 `ic_calendars_*` / `ic_christmas_*` 等素材，列表会自动显示
    static func loadCategories() -> [CardCategory] {
        let holiday = [
            CardItem(id: "h1", source: .named("greet1"), title: nil),
            CardItem(id: "h2", source: .named("greet2"), title: nil),
            CardItem(id: "h3", source: .named("greet3"), title: nil),
            CardItem(id: "h4", source: .named("greet4"), title: nil),
            CardItem(id: "h5", source: .named("greet5"), title: nil),
            CardItem(id: "h6", source: .named("greet6"), title: nil)
        ]
        let calendars = [
            CardItem(id: "cdemo_3", source: .named("greet01"), title: nil),
            CardItem(id: "cdemo_6", source: .named("greet02"), title: nil),
            CardItem(id: "cdemo_9", source: .named("greet03"), title: nil),
            CardItem(id: "cdemo_12", source: .named("greet04"), title: nil),
           
        ]
        let planners = [
            CardItem(id: "p1", source: .named("refresh_printer"), title: nil),
            CardItem(id: "p2", source: .named("icloud_home_icon"), title: nil),
            CardItem(id: "p3", source: .named("email_home_icon"), title: nil),
            CardItem(id: "p4", source: .named("ic_photo_img"), title: nil)
//            CardItem(id: "p1", source: .named("greet_ic1"), title: nil),
//            CardItem(id: "p2", source: .named("greet_ic2"), title: nil),
//            CardItem(id: "p3", source: .named("greet_ic3"), title: nil),
            
        ]
        return [
            CardCategory(id: "christmas_cards", title: "Holiday Picks", items: holiday),
            CardCategory(id: "calendars", title: "Calendar Templates", items: calendars),
            CardCategory(id: "Planners", title: "Planners", items: planners)
        ]
    }
}
