//
//  ManagerAddress.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/9.
//

import Foundation

extension VerseRange{
    static var globalManagerAddress: ManagerAddress { ManagerAddress.s }
}
extension DAddress {
    static var globalManagerAddress: ManagerAddress { ManagerAddress.s }
}

/// 從 UserDefaults 中取得
class ManagerAddress : NSObject {
    static var s: ManagerAddress = ManagerAddress()
    override init(){
        super.init()
        _cur.verses = StringToVerseRange().main(getFromDefault(),(1,1))
        
    }
    var cur: VerseRange { _cur }
    var curChanged$: IjnEventAny = IjnEvent()
    /// 更新到 UserDefault 中，並觸發事件
    func updateCur(_ addr:VerseRange){
        self._old = _cur
        self._cur = addr
        FHLUserDefaults.s.setCore(.AddressCurrent, VerseRangeToString().main(self._cur.verses, ManagerLangSet.s.curTpBookNameLang))
        self.curChanged$.trigger()
    }
    fileprivate var _cur: VerseRange = VerseRange()
    fileprivate var _old: VerseRange? = nil
    fileprivate func getFromDefault()->String{
        return FHLUserDefaults.s.getCoreString(.AddressCurrent) ?? "創1"
    }
}

