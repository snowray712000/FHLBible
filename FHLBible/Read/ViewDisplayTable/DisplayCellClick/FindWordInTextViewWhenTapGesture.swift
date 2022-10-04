//
//  FindWordInTextViewWhenTapGesture.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/29.
//

import Foundation
import UIKit

class FindWordInTextViewWhenTapGesture {
    func findWord(_ gs: UITapGestureRecognizer,_ v: UITextView) -> String? {
        let location: CGPoint = gs.location(in: v)
        let position: CGPoint = CGPoint(x: location.x, y: location.y)
        guard let position2 = v.closestPosition(to: position) else { return nil }
        let tapPosition: UITextPosition = position2
        guard let textRange: UITextRange = v.tokenizer.rangeEnclosingPosition(tapPosition, with: UITextGranularity.word, inDirection: UITextDirection(rawValue: 1)) else {return nil}
        
        let tappedWord: String? = v.text(in: textRange) ?? nil
        return tappedWord
    }
}
