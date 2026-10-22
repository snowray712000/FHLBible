//
//  FindIndexOfCharInTextView.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/29.
//

import Foundation
import UIKit

class FindIndexOfCharInTextView : IFindIndexOfCharInTextView {
    /// 點到文字的哪個字元 (UTF-16 index)；點在沒有文字的地方 (最後一行之下、行尾之外) 回傳 -1。
    func findIndexOfChar(_ v: UITextView, _ tapGesture: UITapGestureRecognizer) -> Int {
        let ptOfTapGesture = tapGesture.location(in: v)
        
        var xy = ptOfTapGesture
        xy.x -= v.textContainerInset.left
        xy.y -= v.textContainerInset.top
        
        let m = v.layoutManager
        let tc = v.textContainer
        m.ensureLayout(for: tc)
        
        let cntGlyphs = m.numberOfGlyphs
        if cntGlyphs == 0 { return -1 }
        
        // 以「點到的那個 glyph 所在的那一行」判斷是否在文字內。
        // 不可用 boundingRect(forGlyphRange: 字元數 - 1)：glyph 數會比字元數少 (希伯來文母音點等組合字元)，
        // 會取到不存在的 glyph，導致整段文字下方都被當成「沒點到」。
        let idxGlyph = m.glyphIndex(for: xy, in: tc, fractionOfDistanceThroughGlyph: nil)
        let rectLine = m.lineFragmentUsedRect(forGlyphAt: idxGlyph, effectiveRange: nil)
        
        // 行的上下範圍 (含行距) 與左右範圍；左右各給一點寬容
        if xy.y < rectLine.minY || xy.y > rectLine.maxY { return -1 }
        if xy.x < rectLine.minX - 4 || xy.x > rectLine.maxX + 4 { return -1 }
        
        return m.characterIndexForGlyph(at: idxGlyph)
    }
}
