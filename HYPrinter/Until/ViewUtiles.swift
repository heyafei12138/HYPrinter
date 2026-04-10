//
//  ViewUtiles.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//

@_exported import JKSwiftExtension
@_exported import SnapKit

import Foundation

let kWindow = UIApplication.jk.keyWindow
let kScreenWidth = UIScreen.main.bounds.width
let kScreenHeight = UIScreen.main.bounds.height
// MARK: - 状态栏高度和导航条高度
let kStatusBarHeight = jk_kStatusBarFrameH
let kNavHeight = 44 + kStatusBarHeight
// MARK: - 底部安全区域高度和tabbar的高度
public var kBottomSafeHeight = jk_kSafeDistanceBottom
let kTabbarHeight = jk_kTabbarFrameH
