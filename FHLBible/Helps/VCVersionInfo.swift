//
//  VCVersionInfo.swift
//  FHLBible
//
//  版本資訊畫面：資料來自 app_versions.md。每個區段（To Do、各版本）是一個 section，
//  每一條說明是一列。手機寬度放不下多欄表格，所以用分組列表。
//  2026-10-21 起改用 SwiftUI（最低 iOS 17）；VCVersionInfo 只是把它包成 UIViewController，
//  讓 VCIndex 仍可 `pushViewController(VCVersionInfo(), …)`。
//

import Foundation
import SwiftUI
import UIKit

struct VersionInfoView: View {
    private let sections: [DVersionInfoSection]

    init() {
        let loaded = VersionInfoParser.loadFromBundle()
        if loaded.isEmpty {
            sections = [DVersionInfoSection(title: NSLocalizedString("版本資訊", comment: ""), date: nil,
                                            items: [NSLocalizedString("找不到版本資訊", comment: "")])]
        } else {
            sections = loaded
        }
    }

    var body: some View {
        List {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                Section {
                    ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                        Text(verbatim: item)
                    }
                } header: {
                    Text(verbatim: header(of: section))
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("版本資訊", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(of s: DVersionInfoSection) -> String {
        var re = s.title
        if let d = s.date { re += "  \(d)" }
        // 最新版 = To Do 之後的第一個區段
        if !s.isToDo, sections.first(where: { !$0.isToDo })?.title == s.title {
            re += "  " + NSLocalizedString("最新", comment: "")
        }
        return re
    }
}

class VCVersionInfo: UIHostingController<VersionInfoView> {
    init() {
        super.init(rootView: VersionInfoView())
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: VersionInfoView())
    }
}
