//
//  FindIndexOfCharInTextView.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/29.
//

import Foundation
import UIKit

class FindIndexOfCharInTextView : IFindIndexOfCharInTextView {
    func findIndexOfChar(_ v: UITextView, _ tapGesture: UITapGestureRecognizer) -> Int {
        let ptOfTapGesture = tapGesture.location(in: v)
        
        var xy = ptOfTapGesture
        xy.x -= v.textContainerInset.left
        xy.y -= v.textContainerInset.top
        
        if isNotInFirstAndEndCharacter(xy, v) {
            return -1
        }
        
        let m = v.layoutManager
        return m.characterIndex(for: xy, in: v.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
    
    private func isNotInFirstAndEndCharacter(_ p: CGPoint,_ v: UITextView) -> Bool {
        let m = v.layoutManager
        let texts = m.textStorage!.length
        let rr1 = m.boundingRect(forGlyphRange: NSRange(location: 0, length: 1), in: m.textContainers[0]) // {5,0} {484,0 18x22} // 希伯來文，順序反過來
        let rr2 = m.boundingRect(forGlyphRange: NSRange(location: texts-1, length: 1), in: m.textContainers[0]) // {231,46} {5,0 5x22}
 
        
        let xx = [rr1.minX,rr2.minX,rr1.maxX,rr2.maxX]
        let yy = [rr1.minY,rr2.minY,rr1.maxY,rr2.maxY]
        
        if p.x < xx.min()! || p.y < yy.min()! {
            return true
        }
        if p.y > yy.max()! {
            return true
        }
                
//        // 原本程式，非 希伯來文 時
//        if rr1.minX <= rr2.minX {
//            if p.x < rr1.minX || p.y < rr1.minY {
//                return true // not in
//            }
//            if p.y > rr2.maxY {
//                return true // not in
//            }
//
//            if  rr2.minY <= p.y && p.y <= rr2.maxY  {
//                if p.x > rr2.maxX {
//                    return true
//                }
//            }
//        } else {
//            // 新增 希伯來文 條件時
//            if p.x < rr2.minX || p.y < rr2.minY {
//                return true // not in
//            }
//            if p.y > rr1.maxY {
//                return true // not in
//            }
//
//            if  rr1.minY <= p.y && p.y <= rr1.maxY  {
//                if p.x > rr1.maxX {
//                    return true
//                }
//            }
//        }
        
        
        return false
    }
    
}
