//
//  VCIndex.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/28.
//
//  2026-10-23 起首頁改用 SwiftUI（最低 iOS 17）。
//  - `HomeView`：App 圖示與名稱、「繼續閱讀」（顯示目前章節與譯本，點了進閱讀）、資料／設定／教學、版本資訊。
//  - `VCIndex` 是包它的 `UIHostingController`，由 `SceneDelegate` 以程式碼放進 `UINavigationController` 當 root
//    （Info.plist 已不再指定 Main.storyboard 為啟動 storyboard，啟動畫面是 LaunchScreen.storyboard）。
//  - 資料庫（AutoLoadDUiabv）初始化與「等到譯本清單載入後才進閱讀」仍在 VCIndex（需要 push）。
//

import Foundation
import SwiftUI
import UIKit
import ZIPFoundation
import zlib
import AVFoundation
import FHLCommon
import OSLog
import Observation

/// 首頁畫面狀態
@Observable
final class HomeModel {
    /// 目前章節，例如「創世記 1」
    var addrText = ""
    /// 目前譯本，例如「和合本 +1」
    var versText = ""
    /// 等待譯本清單載入、尚未進入閱讀
    var isOpening = false
    /// 等太久仍取不到譯本清單 (多半是沒有網路)
    var isLoadFailed = false

    /// 從閱讀回來時要更新 (閱讀會改變目前位址與譯本)
    func refresh() {
        let verses = ManagerAddress.s.cur.verses
        addrText = verses.isEmpty ? "" : VerseRangeToString().main(verses, ManagerLangSet.s.curTpBookNameLang)

        let names = ManagerBibleVersions.s.cur.map { BibleVersionConvertor().na2cna($0) }
        if names.count <= 1 {
            versText = names.first ?? ""
        } else {
            versText = "\(names[0]) +\(names.count - 1)"
        }
    }
}

/// 首頁各項目的動作。push 需要 UINavigationController，所以由 VCIndex 實作。
struct HomeActions {
    var read: () -> Void = {}
    var data: () -> Void = {}
    var setting: () -> Void = {}
    var help: () -> Void = {}
    var versionInfo: () -> Void = {}
}

struct HomeView: View {
    let model: HomeModel
    let actions: HomeActions
    /// 發版本時的版本號與日期 (VCIndex 提供)
    let versionText: String

    var body: some View {
        List {
            header
            Section {
                readButton
            }
            Section {
                menuRow(NSLocalizedString("資料", comment: ""),
                        detail: NSLocalizedString("下載與管理譯本", comment: ""),
                        symbol: "internaldrive", tint: .orange, action: actions.data)
                menuRow(NSLocalizedString("設定", comment: ""),
                        detail: NSLocalizedString("當機重置、回報問題", comment: ""),
                        symbol: "gearshape", tint: .gray, action: actions.setting)
                menuRow(NSLocalizedString("教學", comment: ""),
                        detail: NSLocalizedString("各項功能的使用方式", comment: ""),
                        symbol: "questionmark.circle", tint: .green, action: actions.help)
            }
            Section {
                Button(action: actions.versionInfo) {
                    HStack(spacing: 12) {
                        icon("info", tint: .indigo)
                        Text(NSLocalizedString("版本資訊", comment: ""))
                        Spacer()
                        Text(verbatim: versionText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        chevron
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .listStyle(.insetGrouped)
        .onAppear { model.refresh() }
        .alert(NSLocalizedString("無法取得譯本清單", comment: ""),
               isPresented: Binding(get: { model.isLoadFailed }, set: { model.isLoadFailed = $0 })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(NSLocalizedString("請確認網路連線後，再試一次。", comment: ""))
        }
    }

    /// App 名稱 (原本是 storyboard 上方的一顆標題按鈕)
    private var header: some View {
        VStack(spacing: 8) {
            // App 圖示 (Assets 的 FHLLOGO，也被 ActiveBackgroundAudio 使用)，圓角比例同 iOS 圖示
            Image("FHLLOGO")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 80 * 0.2237, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                .accessibilityHidden(true)
            Text(NSLocalizedString("信望愛聖經工具", comment: ""))
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    /// 最主要的動作：從上次讀到的地方繼續讀
    private var readButton: some View {
        Button(action: actions.read) {
            HStack(spacing: 12) {
                icon("book", tint: .accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("閱讀", comment: ""))
                        .font(.headline)
                    if !model.addrText.isEmpty {
                        Text(verbatim: model.addrText)
                            .font(.subheadline)
                    }
                    if !model.versText.isEmpty {
                        Text(verbatim: model.versText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if model.isOpening {
                    ProgressView()
                } else {
                    chevron
                }
            }
            .padding(.vertical, 6)
        }
        .foregroundStyle(.primary)
        .disabled(model.isOpening)
        .accessibilityHint(NSLocalizedString("從上次讀到的地方繼續", comment: ""))
    }

    private func menuRow(_ title: String, detail: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon(symbol, tint: tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title)
                    Text(verbatim: detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                chevron
            }
        }
        .foregroundStyle(.primary)
    }

    /// 像「設定」App 的彩色圓角方塊圖示
    private func icon(_ symbol: String, tint: Color) -> some View {
        Image(systemName: symbol)
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(tint, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .accessibilityHidden(true)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

class VCIndex : UIHostingController<HomeView> {
    var logger = Logger(subsystem: "com.FHLBible", category: "VCIndex")

    private let model: HomeModel

    // 發版本 (供 關鍵字搜尋，提醒 發版本要改什麼)
    // 版本資訊內容在 Helps/app_versions.md，發版本時一併更新
    private static let labelDate = "2026.10.23d"
    private static let labelVer = "4.13.1" //version

    init() {
        let m = HomeModel()
        self.model = m
        super.init(rootView: HomeView(model: m, actions: HomeActions(), versionText: Self.versionText))
        // actions 需要 self (push)，所以 super.init 之後再換上
        rootView = HomeView(model: m, actions: makeActions(), versionText: Self.versionText)
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let m = HomeModel()
        self.model = m
        super.init(coder: aDecoder, rootView: HomeView(model: m, actions: HomeActions(), versionText: Self.versionText))
    }

    private static var versionText: String { "\(labelVer) (\(labelDate))" }

    override func viewDidLoad() {
        super.viewDidLoad()
        AutoLoadDUiabv.fnGFromSQLite = gAutoLoadDuiabvSQLite
        _ = AutoLoadDUiabv.s // lazy var

        // 子畫面返回鈕的文字 (預設會顯示 Back)
        navigationItem.backButtonTitle = NSLocalizedString("首頁", comment: "")
    }

    private func makeActions() -> HomeActions {
        var actions = HomeActions()
        actions.read = { [weak self] in self?.goRead() }
        actions.data = { [weak self] in self?.navigationController?.pushViewController(VCData(), animated: true) }
        actions.setting = { [weak self] in self?.navigationController?.pushViewController(VCSettings(), animated: true) }
        actions.help = { [weak self] in self?.navigationController?.pushViewController(VCHelps(), animated: true) }
        actions.versionInfo = { [weak self] in self?.navigationController?.pushViewController(VCVersionInfo(), animated: true) }
        return actions
    }

    private func goRead() {
        // 若程式，開始的時候，沒有網路。
        logger.info("AutoLoadDUiabv record count: \(AutoLoadDUiabv.s.record.count)")
        if AutoLoadDUiabv.s.record.count == 0 {
            AutoLoadDUiabv.s.reloadAsync()
        }

        // 等譯本清單載入才能進閱讀。等的時候首頁的「閱讀」顯示轉圈並停用，避免連點 push 多次。
        model.isOpening = true
        testThenDoAsync({ AutoLoadDUiabv.s.record.count != 0 }, { [weak self] in
            guard let self = self else { return }
            self.model.isOpening = false
            let vc1 = self.gVCRead()
            let addr = VerseRange.globalManagerAddress.cur
            let vers = ManagerBibleVersions.s.cur
            vc1.setInitData(addr, vers)
            self.navigationController?.pushViewController(vc1, animated: true)
        })
        // testThenDoAsync 約 0.3 秒一次、最多 50 次後放棄且不回報，這裡多等一下再告知使用者
        DispatchQueue.main.asyncAfter(deadline: .now() + 17) { [weak self] in
            guard let self = self, self.model.isOpening else { return }
            self.model.isOpening = false
            self.model.isLoadFailed = true
        }
    }
}
