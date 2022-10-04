//
//  FindWhichDTextFromIndexOfChar.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/29.
//

import Foundation

class FindWhichDTextFromIndexOfChar : IFindWhichDTextFromIndexOfChar {
    init(_ isVisibleSn:Bool){
        _isVisibleSn = isVisibleSn
    }
    /// false 時，若是 sn，不能計它的 cnt
    private var _isVisibleSn: Bool!
    func findWhichDText(_ dtexts: [DText], _ idxChar: Int) -> DText? {
        if idxChar == -1 { return nil }
        if dtexts.count == 0 { return nil }

        sum = 0
        self.idxChar = idxChar
        
        let re = doArray(dtexts)
        
        return re ?? dtexts.last!
    }
    private func doArray(_ ds:[DText])->DText? {
        for a1 in ds {
            if a1.children != nil {
                sum = sum + a1.cntCharContainFront
                if chk() { return a1 } // 剛好落在 ( ) 的前面那個 ( 字元
                let re = doArray(a1.children!)
                if re != nil { return re } // 落在 child 的某一個
                sum = sum + a1.cntCharContainBack
                if chk() { return a1 } // 剛好落在 ( ) 的後面那個 ) 字元
            } else {
                // sn visible
                if _isVisibleSn || a1.sn == nil {
                    sum = sum + a1.cntChar
                }
                
                if chk() { return a1 } // 落在這個字
            }
        }
        return nil
    }
    private func chk()-> Bool { sum > idxChar }
    var sum = 0 // 目前累計
    var idxChar = -1 // click 的 index
    
}
