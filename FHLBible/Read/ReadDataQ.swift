//
//  ReadDataQ.swift
//  FHLBible
//
//  Created by littlesnow on 2021/12/1.
//

import Foundation
import UIKit
/// 用現有的  BibleReadDataGetter 去湊
class ReadDataQ : NSObject, IVCReadDataQ {
    var qDataForRead$: IjnEventOnce<Any, (OneRow, [OneRow])> = IjnEventOnce()
    
    // var _tp: BookNameLang = .太
    var _tp: BookNameLang { ManagerLangSet.s.curTpBookNameLang }
    func qDataForReadAsync(_ addr: String, _ vers: [String]) {
        
        // 核心是用 BibleReadDataGetter class
        BibleReadDataGetter().queryAsync(vers, addr) { _, datas in
            
            let r2 = self.getVersionTitle(vers)
            let r2a = r2.map({[DText($0,isParenthesesHW: true)]})
            let r5 = (header:[DText()],datas:r2a)
            
            let r1 = self.getAddressListEachRowHeader(datas) // 也就是，有 r1 row 資料
            if r1.count == 0 {
                // 特例，所選的版本們，都沒有這裡的經文
                self.qDataForRead$.triggerAndCleanCallback(nil, (r5, self._gNoData(vers.count)))
            } else {
                let r1a = r1.map({[DText($0, refDescription: $0,isInTitle: false)]})
                let r4 = ijnRange(0, r1a.count).map { i-> OneRow in
                    let r3a = r1a[i]
                    let r3b = datas[i].map({$0.children ?? [DText("(此譯本無)")]})
                    return (header: r3a, datas: r3b)
                }
                
                let re = (r5, r4)
                self.qDataForRead$.triggerAndCleanCallback(nil, re)
            }
        }
    }
    typealias OneRow = ViewDisplayTable2.OneRow
    private func _gNoData(_ cntVer:Int) -> [([DText],[[DText]])]{
        let r1 = [DText()]
        let r2 = ijnRange(0, cntVer).map({ _ in [DText("(此譯本無)")]})
        
        return [(r1,r2)]
    }
    
    // ["創1:1","創1:2"]
    fileprivate func getAddressListEachRowHeader(_ datas:[[DOneLine]]) -> [String] {
        return datas.map ({ a1 -> String in
            // a1.first 說不定 first 是空的
            let r1 = a1.ijnFirstOrDefault({$0.addresses != nil})
            if r1 == nil {
                return "" // 都是空的
            }
            
            // 從 book:1,chap:1,verse:1 得到 創1
            let r2 = StringToVerseRange().main(r1!.addresses!, nil)
            if r2.count == 0 {
                return "" // addr 字串轉換不回, 可能是沒考慮到的 case
            }
            return VerseRangeToString().main(r2, self._tp)
        })
    }
    /// [和合本 新譯本]
    fileprivate func getVersionTitle(_ vers:[String])->[String] {
        return vers.map({BibleVersionConvertor().na2cna($0)})
    }
    
    
}
