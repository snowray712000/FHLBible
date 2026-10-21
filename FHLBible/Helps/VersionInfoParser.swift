//
//  VersionInfoParser.swift
//  FHLBible
//
//  解析 app_versions.md（App bundle 內附）。格式說明見該檔開頭的註解。
//

import Foundation

/// 版本資訊的一個區段：To Do 或某個版本
struct DVersionInfoSection {
    /// To Do 或版本號，例如 "4.11.1"
    var title: String
    /// 發版本日期，例如 "2026.04.13a"。To Do 沒有。
    var date: String?
    var items: [String]
    var isToDo: Bool { title.lowercased().replacingOccurrences(of: " ", with: "") == "todo" }
}

enum VersionInfoParser {
    static let fileName = "app_versions"
    static let fileExtension = "md"

    /// 讀 bundle 內的 app_versions.md。找不到或讀不到回傳空陣列。
    static func loadFromBundle(_ bundle: Bundle = .main) -> [DVersionInfoSection] {
        guard let url = bundle.url(forResource: fileName, withExtension: fileExtension),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return parse(text)
    }

    static func parse(_ text: String) -> [DVersionInfoSection] {
        var re: [DVersionInfoSection] = []
        var isInComment = false

        for line0 in text.components(separatedBy: .newlines) {
            // <!-- ... --> 註解（可跨行）
            var line = line0
            if isInComment {
                guard let r = line.range(of: "-->") else { continue }
                line = String(line[r.upperBound...])
                isInComment = false
            }
            while let s = line.range(of: "<!--") {
                if let e = line.range(of: "-->", range: s.upperBound..<line.endIndex) {
                    line.removeSubrange(s.lowerBound..<e.upperBound)
                } else {
                    line = String(line[..<s.lowerBound])
                    isInComment = true
                }
            }

            if line.hasPrefix("## ") {
                let (title, date) = splitTitleAndDate(String(line.dropFirst(3)))
                re.append(DVersionInfoSection(title: title, date: date, items: []))
            } else if line.hasPrefix("- "), !re.isEmpty {
                re[re.count - 1].items.append(String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces))
            } else if let c = line.first, c == " " || c == "\t", !re.isEmpty, !re[re.count - 1].items.isEmpty {
                // 續行
                let t = line.trimmingCharacters(in: .whitespaces)
                if !t.isEmpty { re[re.count - 1].items[re[re.count - 1].items.count - 1] += "\n" + t }
            }
        }
        return re
    }

    /// "4.11.1 (2026.04.13a)" → ("4.11.1", "2026.04.13a")；沒有括號時 date 為 nil
    static func splitTitleAndDate(_ s: String) -> (String, String?) {
        let t = s.trimmingCharacters(in: .whitespaces)
        guard t.hasSuffix(")"), let open = t.lastIndex(of: "(") else { return (t, nil) }
        let title = t[..<open].trimmingCharacters(in: .whitespaces)
        let date = t[t.index(after: open)..<t.index(before: t.endIndex)].trimmingCharacters(in: .whitespaces)
        return (title, date.isEmpty ? nil : date)
    }
}
