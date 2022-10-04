//
//  DataForDrawTable.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/17.
//

import Foundation


/// 這個 class 核心在負責，qsb api 抓資料，不是在串流程，所以上色應該是別人的事。
/// 但處理資料也不該是 view table 的事，而應該是 ctrl 的事 VCSearchResult
/// ... 但資料包含它的 該繪什麼，硬要算它的也是可以啦 ...
class DataForDrawTable : IViewDisplayTable2DataQ {
    /// 第2個參數, 是指 目前 opt 時, 所有的 datas, 而非所有找到的 addr
    init(_ vers:[String],_ datasAddrs:[DAddress],_ fnColorIt: FnColorIt?){
        self._vers = vers
        self._datasAddr = [:]
        self._datas = [:]
        self._iColorItWhenOneQueryed = fnColorIt
        
        // _datasAddr 初始, row : addr
        datasAddrs.enumerated().forEach({self._datasAddr[$0.offset]=$0.element})
        
        // _datas 初始, row : (DText[], DText[][])
        self._resetDatasFromAddress()
        
        _datasOnChanged$.addCallback { sender, pData in
            self._updateDatasQueryingWhenFinishOnce()
            self.onDatasGetter$.trigger(self, nil)
        }
        
        // 開始，不作事？ 對，到時候人家(tableview) 會呼叫 query
    }
    /// 會被 tableview 呼叫，而且是多執行緒
    /// 此 class 主要進入點
    func queryDataAsync(_ rows: [Int]) {
        
        let r3 = OneQuery()
        r3.rows = self._gQueryRows(rows)
        if r3.rows!.count == 0 {
            return // 別人在抓，也包含它的
        }
        r3.qDataForRead$.addCallback { sender, pData in
            // pData.0 當然就是 和合本 新譯本 這 row
            // pData.1 開始才是資料
            let r2 = r3.rows!
            if pData != nil {
                // 抓了一堆資料
                self._updateDatasWhenFinishOnce(pData!.1, r3)
            } else {
                // 沒資料!? 把 querying 中移除
                self._updateDAtasQueryWhenQueryFailure(r2)
            }
            
            self._threads.removeAll(where: {$0 == r3})
            self._datasOnChanged$.trigger(nil, nil)
        }
        _threads.append(r3)
        r3.qDataForReadAsync(_vers)
    }
    
    typealias FnColorIt = (_ row:ReadDataQ.OneRow) -> Void
    var _iColorItWhenOneQueryed: FnColorIt?
    var isAlreadyNoUse: Bool = false
    /// 所有繪圖該有的資料, 但若資料還沒有，就是 nil
    var datas: [Int : ([DText], [[DText]]?)] { _datas }
    /// 所有, 當 _curOpt 時, 會有的 row index
    /// 0-based
    var _datas: [Int : ([DText], [[DText]]?)]
    var _datasOnChanged$: IjnEventAny = IjnEvent()
    func _resetDatasFromAddress(){
        let cnt = _datasAddr.count
        
        for r in 0..<cnt {
            let r1 = _datasAddr[r]!
            let bk =  BibleBookNames.getBookName(r1.book, ManagerLangSet.s.curTpBookNameLang)
            let ref = "\(bk) \(r1.chap)"
            let w = "\(ref):\(r1.verse)"
            let r2 = DText(w, refDescription: ref, isInTitle:  false )
            self._datas[r] = ([r2], nil)
        }
    }
    /// 不 trigger, 只是更新 _datas
    /// data 是剛剛抓到的新資料
    /// queryor 是這次發起的 thread, 主要會用它的 rows 就是當時發出的參數.
    func _updateDatasWhenFinishOnce(_ data:[ReadDataQ.OneRow],_ queryor:OneQuery){
        
        // 理論上， queryor.rows 數量等同於 data
        func doEach(_ da:ReadDataQ.OneRow){
            let r2 = StringToVerseRange().main(da.header.first!.w!, nil).first!
            let r3 = queryor.rows!.first(where: {$0.addr == r2})
            if r3 != nil {
                _colorItWhenSetToDatas(da)
                self._datas[r3!.row] = da
            }
        }
        
        data.forEach(doEach)
    }
    func _colorItWhenSetToDatas(_ dataOneRow: ReadDataQ.OneRow){
        if self._iColorItWhenOneQueryed != nil {
            self._iColorItWhenOneQueryed!(dataOneRow)
        }
    }
    /// 對應 _datas 的 addr (這樣才能執行 query  動作)
    /// 0-based
    var _datasAddr: [Int: DAddress ]!
    /// 有這個才能執行 query 動作
    var _vers: [String]
    
    var onDatasGetter$: IjnEvent<IViewDisplayTable2DataQ, Any> = IjnEvent()
    
    
   
    /// _datas 中哪些 row 沒有 data
    var datasNoData: Set<Int> { _datas.filter({$0.value.1 == nil}).map({$0.key}).ijnToSet() }
   
    /// --> _datasQuerying
    var datasQuering: Set<Int> { _datasQuering }
    var _datasQuering: Set<Int> = Set()
    func _updateDatasQueryingWhenFinishOnce() {
        let r1 = datas.map({$0.key}) // 有的 index
        r1.forEach({_datasQuering.remove($0)})
    }
    func _updateDatasQueryWhenStartingOnce(_ data:[OneRow]){
        data.map({$0.row}).forEach({_datasQuering.insert($0)})
    }
    func _updateDAtasQueryWhenQueryFailure(_ data:[OneRow]){
        data.map({$0.row}).forEach({_datasQuering.remove($0)})
    }
    /// 產生的查詢過程
    var _threads: [OneQuery] = []
    
    class OneQuery : ReadDataQ {
        var rows: [DataForDrawTable.OneRow]?
        /// super 的 addr 參數，從 rows 算出來了
        func qDataForReadAsync(_ vers: [String]) {
            let addr = VerseRangeToString().main(rows!.map({$0.addr}), ManagerLangSet.s.curTpBookNameLang )
            super.qDataForReadAsync(addr, vers)
        }
    }
    func _gQueryRows(_ rows:[Int])->[DataForDrawTable.OneRow]{
        let cnt = _datas.count
        let r1 = rows.filter({$0 >= 0 && $0 < cnt &&  datasNoData.contains($0) && !datasQuering.contains($0)})
        
        return r1.map { OneRow($0, _datasAddr[$0]!) }
    }
    class OneRow {
        init(_ r:Int,_ addr:DAddress){
            self.row = r
            self.addr = addr
        }
        var row: Int!
        var addr: DAddress!
        /// 多個版本 (output)
        var datas: [[DText]]?
        func addrToDText()-> [DText] {
            let tp = ManagerLangSet.s.curTpBookNameLang
            let ref = "\(addr.toString(tp)) \(addr.chap)"
            let w = "\(ref):\(addr.verse)"
            return [DText(w,refDescription: ref,isInTitle: false)]
        }
        /// 產生給 result 用到
        func datasToResult() -> ([DText],[[DText]]){
            return (addrToDText(),datas!)
        }
    }
    
    
}
