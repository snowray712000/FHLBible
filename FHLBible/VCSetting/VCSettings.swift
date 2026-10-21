//
//  VCSettings.swift
//  FHLBible
//
//  Created by littlesnow on 2021/12/1.
//
//  2026-10-21 起改用 SwiftUI（最低 iOS 17）。VCSettings 只是把 SettingsView 包成
//  UIViewController，讓 VCIndex 仍可 `pushViewController(VCSettings(), …)`。
//  （此資料夾是傳統 group，所以 SettingsView 直接放在這個既有檔案，免得要在 Xcode 內加檔案。）
//

import Foundation
import SwiftUI
import UIKit
import FHLCommon

struct SettingsView: View {
    private static let supportUrl = "https://bible.fhl.net/ios/FHLBibleSupport/index.html"

    @Environment(\.openURL) private var openURL
    @State private var isResetDone = false
    @State private var isAskOpenSupport = false

    var body: some View {
        List {
            Button { doReset() } label: {
                row(NSLocalizedString("當機重置", comment: ""),
                    NSLocalizedString("程式總是有Bug，當「閱讀」總是閃退，可能是某譯本、某章、某節、我沒處理好。按此功能，嘗試重置為「和合本，創世記1」", comment: ""),
                    titleColor: .blue)
            }
            Button { isAskOpenSupport = true } label: {
                row("Bugs",
                    NSLocalizedString("請至 support urls 回報{或觀看}目前已提出的問題與回饋。", comment: ""),
                    titleColor: .primary)
            }
        }
        .navigationTitle(NSLocalizedString("設定", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .alert(NSLocalizedString("訊息", comment: ""), isPresented: $isResetDone) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(NSLocalizedString("已重置，可再嘗試使用(1秒後繼續)", comment: ""))
        }
        .alert(NSLocalizedString("打開到 support urls嗎？(https://bible.fhl.net/ios/FHLBibleSupport/index.html)", comment: ""),
               isPresented: $isAskOpenSupport) {
            Button("Cancel", role: .cancel) {}
            Button("OK") {
                if let url = URL(string: Self.supportUrl) { openURL(url) }
            }
        }
    }

    private func row(_ title: String, _ detail: String, titleColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: title).foregroundColor(titleColor)
            Text(verbatim: detail).font(.subheadline).foregroundColor(.secondary)
        }
    }

    private func doReset() {
        ManagerAddress.s.updateCur(VerseRange(DAddress(1,1,1).generateEntireThisChap()))
        ManagerBibleVersions.s.updateCur(["unv"])
        ManagerIsSnVisible.s.updateCur(true)

        isResetDone = true
        // 原本是 1 秒後自動關閉訊息
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { isResetDone = false }
    }
}

class VCSettings: UIHostingController<SettingsView> {
    init() {
        super.init(rootView: SettingsView())
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: SettingsView())
    }
}
