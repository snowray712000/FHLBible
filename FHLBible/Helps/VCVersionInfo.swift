//
//  VCVersionInfo.swift
//  FHLBible
//
//  版本資訊畫面：資料來自 app_versions.md。每個區段（To Do、各版本）是一個 section，
//  每一條說明是一列。手機寬度放不下多欄表格，所以用分組列表。
//

import Foundation
import UIKit

class VCVersionInfo: UITableViewController {
    private var sections: [DVersionInfoSection] = []

    init() {
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) {
        super.init(style: .insetGrouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("版本資訊", comment: "")
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        sections = VersionInfoParser.loadFromBundle()
        if sections.isEmpty {
            sections = [DVersionInfoSection(title: NSLocalizedString("版本資訊", comment: ""), date: nil,
                                            items: [NSLocalizedString("找不到版本資訊", comment: "")])]
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let s = sections[section]
        var re = s.title
        if let d = s.date { re += "  \(d)" }
        // 最新版 = To Do 之後的第一個區段
        if !s.isToDo, sections.first(where: { !$0.isToDo })?.title == s.title {
            re += "  " + NSLocalizedString("最新", comment: "")
        }
        return re
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.text = sections[indexPath.section].items[indexPath.row]
        return cell
    }
}
