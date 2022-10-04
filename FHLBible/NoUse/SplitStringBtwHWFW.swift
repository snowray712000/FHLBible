//
//  SplitStringBtwHWFW.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/9/10.
//

import Foundation

/// Split String Between 系列，這個是處理 ( )，全型半型都會處理
/// 英文 Parentheses Full Width 是全型小括號；Half Width 是半型小括號
/// 雖本用在 BibleText 轉換為 DText，但預期將來還有別處會用到
/// 因為屬文字處理，所以放在 Tool 資料夾中，與 SplitByRegex 類似
//class SplitStringBtwHWFW : SplitStringBtwBase {
//    override func generateLastRegepx() -> NSRegularExpression {
//        return try! NSRegularExpression(pattern: "\\)|）", options: [])
//    }
//    override func getMinStepWhenReverseFind() -> Int {
//        return -1
//    }
//    override func generateSubStringWhenReverseFound(_ re: NSTextCheckingResult, _ str: String) -> Substring {
//        let r1 = re.range(at: 0)
//        return str[Range(r1, in: str)!]
//    }
//    override func generateFirstRegexp(_ tp: Substring) -> NSRegularExpression {
//        let pattern = tp == ")" ? "\\(" : "（"
//        let reg2 = try! NSRegularExpression(pattern: pattern, options: [])
//        return reg2
//    }
//    override func get3String(_ str: String, _ r1: (idx2: Int, tp: Substring, idx1: Int)) -> (String, String, String) {
//        let idx1 = r1.idx1
//        let idx2 = r1.idx2
//        if (idx2 < idx1 ){
//            print ( "\(str) get3String, 參數不合理 idx1: \(idx1) idx2: \(idx2)" )
//            return (str,"","")
//        } else {
//            let str1 = String(ijnSubString(str, len: idx1))
//            let str2 = String(ijnSubString(str, pos: idx1 + 1, to: idx2))
//            let str3 = String(ijnSubString(str, pos: idx2 + 1)) // ) 長度是1，所以 +1
//            return (str1,str2,str3)
//        }
//    }
//}
