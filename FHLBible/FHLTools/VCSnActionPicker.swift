//
//  VCSnActionPicker.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/28.
//

import Foundation
import UIKit
class VCSnActionPicker : VCPickerBaseOnTableView<DText.SnAction> {
    override func getSelected(_ i: Int) -> DText.SnAction? {
        return types[i]
    }
    var types : [DText.SnAction] = [
        // .list, .parsing, .dict, .cbol, .cbole, .twcb
        // .list, .parsing, .dict, .cbol, .twcb // 不顯示 CBOL English
        .list, .parsing, .cbol, .twcb // 不顯示 全
    ]
    override var _ovTitle1: [String] { data }
    override var _ovTitle2: [String]? { data2 }
    //var data : [String] = [NSLocalizedString("彙編", comment: ""),"Parsing",NSLocalizedString("字典(全)", comment: ""),"CBOL","CBOL(En)",NSLocalizedString("浸宣", comment: "")]
    //var data2 : [String] = ["","",NSLocalizedString("同時顯示 CBOL、浸宣、CBOL(En)的字典", comment: ""),NSLocalizedString("中文線上聖經計畫 (Chinese bible on-line project) CBOL", comment: "") , "English Ver" ,NSLocalizedString("浸宣出版社原文字典", comment: "")]
//    var data : [String] = [NSLocalizedString("彙編", comment: ""),"Parsing",NSLocalizedString("字典(全)", comment: ""),"CBOL",NSLocalizedString("浸宣", comment: "")]
//    var data2 : [String] = ["","",NSLocalizedString("同時顯示 CBOL、浸宣、CBOL(En)的字典", comment: ""),NSLocalizedString("中文線上聖經計畫 (Chinese bible on-line project) CBOL", comment: "") , NSLocalizedString("浸宣出版社原文字典", comment: "")]
    var data : [String] = [NSLocalizedString("彙編", comment: ""),"Parsing","CBOL",NSLocalizedString("浸宣", comment: "")]
    var data2 : [String] = [NSLocalizedString("此原文出現在哪些章節.", comment: ""),NSLocalizedString("此章節的原文分析", comment: ""),NSLocalizedString("中文線上聖經計畫 (Chinese bible on-line project) CBOL", comment: "") , NSLocalizedString("浸宣出版社原文字典(無法提供離線版)", comment: "")]
}
