//
//  ManagerLangSet.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/15.
//

import Foundation

/// 簡體 繁體
/// 已經不在用 Defaults 去取得，而是直接從 api 的值判斷，即 Locale.current.identifier
class ManagerLangSet : NSObject {
    static var s: ManagerLangSet = ManagerLangSet()
    
    var curIsGb: Bool { _isGBViaLocale() }
    /// gb=0 or gb=1，本質是用 curTpBookNameLang
    var curQueryParamGb: String { "gb=\(ManagerLangSet.s.curIsGb ? "1" : "0")" }
    /// 太 or 太 Gb (太常用到了)
    var curTpBookNameLang : BookNameLang {
        // return cur ? .太GB : .太
        // print ( Locale.current.identifier )
        // print (_isGBViaLocale())
        if _isGBViaLocale() {
            return .太GB
        } else if _isBig5ViaLocale() {
            return .太
        } else {
            if _isZhViaLocale() {
                return .太
            }
            return .Mt
        }
    }
    fileprivate func _isGBViaLocale()->Bool {
        let r1 = try! NSRegularExpression(pattern: #"Hans|CN"#, options: [])
        let r2 = ijnMatchFirst(r1, Locale.current.identifier)
        return r2 != nil
    }
    fileprivate func _isBig5ViaLocale()->Bool {
        let r1 = try! NSRegularExpression(pattern: #"Hant|TW"#, options: [])
        let r2 = ijnMatchFirst(r1, Locale.current.identifier)
        return r2 != nil
    }
    fileprivate func _isZhViaLocale()->Bool {
        let r1 = try! NSRegularExpression(pattern: #"zh"#, options: [])
        let r2 = ijnMatchFirst(r1, Locale.current.identifier)
        return r2 != nil
    }
    /// 書卷分類 全部 1-66 舊約 1-39 新約 40-66 摩西五經 1-5
    var curBookClassor : [String: [Int]] {
        return curIsGb ? BibleBookClassor._dictNa2CntGB : BibleBookClassor._dictNa2Cnt
    }
    /// 書卷分類 全部 舊約 新約 摩西五經
    var curBookClassorNaOrder: [String] {
        return curIsGb ? BibleBookClassor._orderNaGB : BibleBookClassor._orderNa
    }
    
}

