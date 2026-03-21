//
//  DataForDrawTable.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/17.
//

import Foundation
import FHLCommon
import OSLog

/// 這個 class 核心在負責，qsb api 抓資料，不是在串流程，所以上色應該是別人的事。
/// 但處理資料也不該是 view table 的事，而應該是 ctrl 的事 VCSearchResult
/// ... 但資料包含它的 該繪什麼，硬要算它的也是可以啦 ...
/// 它重要的 results 是 ._datas 
class DataForDrawTable : IViewDisplayTable2DataQ {
    var logger = Logger(subsystem: "com.FHLBible", category: "DataForDrawTable")
    func _debug_dtextss_to_string(_ dtextss: [[DText]])->String {
        return debug_dtextss_to_string(dtextss," 下一譯本 ")
    }
    func _debug_ReadDataQ_OneRow_to_string(_ r: ReadDataQ.OneRow)->String {
        return _debug_dtextss_to_string(r.datas)
    }
    func _debug_ReadDataQ_OneRows_to_string_random2(_ r: [ReadDataQ.OneRow])->String {
        // r: 在 callback 中，pData!.1 就是 [ReadDataQ.OneRow]
        // 取得亂數 2 個，整數，範圍是 0 到 r.count - 1
        let randomIndices = (0..<r.count).shuffled().prefix(2)
        return randomIndices.map({_debug_ReadDataQ_OneRow_to_string(r[$0])}).joined(separator: " ")

        // 從這函式，可以理解到 qDataForRead 的 callback 回傳值的 pData
        // pData 的 .1 是包含 經節位置，與經文資料
        // pData 的 .1 是個 array。 這資料結構，本來就是設計給 tableview 的 row 的，所以它將 row 的 header datas 綁成一個 tuple
        // 承上，所以顯示所有經文是 .1.map 而不是 .1.datas.map
    }
    func _debug_query_rows_row_and_addr(_ r: [DataForDrawTable.OneRow]) -> String {
        // 這是在 callback 中，的 r3，就是 OneQuery 中的 rows
        return r.map({"\($0.row ?? -1) \(debug_dtexts_to_string($0.addrToDText()))"}).joined(separator: " (下個oneRow)")
    }
    func _debug_query_rows_datas(_ r: [DataForDrawTable.OneRow])->String{
        // 這是在 callback 中的 r3.rows
        // 確認一下，callback 後， r3 的 rows 的 datas 是不是還是空的
        // 確實，還是 nil，而且在呼叫 _updateDatasWhenFinishOnce 之後，仍然沒有填入它的 .datas 值，而真正要填入的是 self._datas ，而非只是 query 的
        
        return r.map({"\($0.datas == nil ? "(nil)" : self._debug_dtextss_to_string($0.datas!))"}).joined(separator: " (下個oneRow)")
    }
    func _debug_info_datas()->String{
        // 想知道目前有多少 keys
        let cntOfkey = self._datas.keys.count
        // 想知道目前有多少 values 是 nil, 多少不是
        // 注意， nil 是 values.1 才是 datas 而 values.0 是 address, 一定不會是 nil
        let cntOfNil = self._datas.values.filter({$0.1 == nil}).count
        let cntOfNotNil = self._datas.values.filter({$0.1 != nil}).count
        
        return "key: \(cntOfkey), nil: \(cntOfNil), notnil: \(cntOfNotNil)"
        
        // 經測試, 一開始會有 所有的 row
        // 然後, 可能會局部取得, 例如， 取得其中 21 個
        // 觸發是 dataview 的 cellRowAtIndex 的 row 上下 20 個
    }
    
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

        // 指定要抓 rows ， 但真正需要抓的是 r3.rows 。
        // 例如，[0,1,2,3,4] 要抓，但是 [0,1,4] 正在抓，或抓過了。就只抓 [2,3]
        // 並且 .rows 不是 Int, 而是 OneRow
        // OneRow class，就是記得 row 與對應的 Address，這兩個都是 input。
        // OneRow class，還會準備 data 來放資料，預設是 nil，因為可能是多個譯本，所以是 DText[][]。
        r3.rows = self._gQueryRows(rows)
        if r3.rows!.count == 0 {
            return // 別人在抓，也包含它的
        }

        r3.qDataForRead$.addCallback { sender, pData in
            // pData.0 當然就是 和合本 新譯本 這 row
            // pData.1 開始才是資料
            let r2 = r3.rows!
            if pData != nil {
                // debug , 列出抓到的資料 pData.1
//                self.logger.debug("pData.1.datas \(self._debug_ReadDataQ_OneRows_to_string_random2(pData!.1))")
                
                // 其實不知道為何需要 pData.0 ，因為經文的 Adress 在 pData.1 也有。
                
                // r3 裡面存的，是這次真正要取的，它就是有 row id 與 row 的 address 。 注意， row 的 address 有可能會有多個，因為有的譯本會將數節合併成一個
//                self.logger.debug("r3.rows \(self._debug_query_rows_row_and_addr(r3.rows!))")
                
                // 如下結果，確實，僅管 pData!.1 已經有資料，但 r3 的 datas 裡是還沒有資料的
//                self.logger.debug("r3.rows data \(self._debug_query_rows_datas(r3.rows!))")
                
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

