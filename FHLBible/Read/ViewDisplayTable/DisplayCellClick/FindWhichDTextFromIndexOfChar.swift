//
//  FindWhichDTextFromIndexOfChar.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/29.
//

import Foundation
import FHLCommon

/// 第 n 個字元落在哪個 DText 的範圍，就是哪個 DText。
/// 範圍由 `ViewDisplayCell` 轉字串時，用實際長度記錄 (見 `DTextDrawToAttributeString.mainConvertWithSource`)；
/// 隱藏的 SN 長度為 0，自然不會被選到。
class FindWhichDTextFromIndexOfChar : IFindWhichDTextFromIndexOfChar {
    func findWhichDText(_ ranges: [DTextCharRange], _ idxChar: Int) -> DText? {
        if idxChar < 0 { return nil }
        return ranges.first(where: { NSLocationInRange(idxChar, $0.range) })?.dtext
    }
}
