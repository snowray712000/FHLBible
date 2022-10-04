//
//  VCVerseActionPicker.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/28.
//

import Foundation
import UIKit

public enum VerseAction {
    case InfoParsing // 原文分析
    case InfoComment // 注釋
    case InfoTsk //串珠
    case VersionsCompare // 版本比較
}


class VCVerseActionPicker : VCPickerBaseOnTableView<VerseAction> {
    override func getSelected(_ i: Int) -> VerseAction? {
        switch i {
        case 0:
            return .VersionsCompare
        case 1:
            return .InfoParsing
        case 2:
            return .InfoComment
        case 3:
            return .InfoTsk
        default:
            return nil
        }
    }
    override var _ovTitle1: [String] {
        return [NSLocalizedString("版本比較", comment: ""),"Parsing",NSLocalizedString("注釋", comment: ""),NSLocalizedString("串珠", comment: "")]
    }
    override var _ovTitle2: [String]? {
        return [NSLocalizedString("此節，比較多個版本", comment: ""),
                NSLocalizedString("原文分析工具；時態、單複數、陽性、陰性等原文分析", comment: ""),
                NSLocalizedString("查經班查經後資料整理，完整可見 https://a2z.fhl.net/bible/，或 google 'a2z fhl' 即可。", comment: ""),
                NSLocalizedString("串珠聖經工具。每一節經文旁，標注相關經文，它也是一種注釋，不是聖經本身", comment: ""),
                ""
        ]
    }
    override var _ovIsLastRedForCancel: Bool { false }
    var types : [DText.SnAction] = [
        .list, .dict, .cbol, .cbole, .twcb
    ]
    var data : [String] = [NSLocalizedString("彙編", comment: ""),NSLocalizedString("字典(全)", comment: ""),"CBOL","CBOL(En)",NSLocalizedString("浸宣", comment: ""),"Cancel"]
    var data2 : [String] = ["",NSLocalizedString("同時顯示 CBOL、浸宣、CBOL(En)的字典", comment: ""),NSLocalizedString("中文線上聖經計畫 (Chinese bible on-line project) CBOL", comment: "") , "English Ver" ,NSLocalizedString("浸宣出版社原文字典", comment: ""),""]
}
