//
//  File.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/9/10.
//

import Foundation
import IJNSwift
import FMDB
/// 為了 BibleReadDataGetter
protocol IBibleGetter {
    /// ver: unv
    func queryAsync(_ ver: String,_ addr: String,_ fn: @escaping (_ datas:[DOneLine])->Void )
}

/// 幫助理解 IBibleGetter
class BibleGetter01 : IBibleGetter{
    func queryAsync(_ ver: String, _ addr: String, _ fn: @escaping ([DOneLine]) -> Void) {
        
        let r1 = DOneLine()
        r1.addresses = "Ge1:3"
        r1.children = [DText("　神說：「要有光」，就有了光。")]
        
        let r2 = DOneLine()
        r1.addresses = "Ge1:4"
        r1.children = [DText("　神看光是好的，就把光暗分開了。")]
        
        let r3 = DOneLine()
        r1.addresses = "Ge1:5"
        r1.children = [DText("　神稱光為「晝」，稱暗為「夜」。有晚上，有早晨，這是頭一日。")]
        
        let re = [r1,r2,r3]
        fn(re)
    }
}



/// 為了 IDataGetter 開發,
/// 最主要 protocol 有
/// 1. 將 qsb 的結果, 轉為 DOneLine (用在第3)
/// 2. 版本轉換，即 "和合本" "新譯本" to unv 等概念 (用在第1)
/// 3. 取得經文資料 ( a. 透過 api, b. 透過 local file)
class BibleReadDataGetter {
    typealias FnCallback = (_ vers:[DOneLine],_ datas:[[DOneLine]] )->Void
    /// "和合本" : 的 data 結果 (多執行緒在存)
    private var datas = [String:[DOneLine]]()
    private var addr: String = ""
    /// "和合本" "新譯本" 原本的順序，在 merge 時會用到這順序
    private var vers: [String] = []
    private var bibleG: IBibleGetter
    init (){
        // self.bibleG = BibleGetter01()
        // self.bibleG = BibleGetterViaFhlApiQsb()
        // self.bibleG = BibleGetterViaSQLiteFile()
        self.bibleG = BibleGetterViaSQLiteOrApi()
    }
    func queryAsync(_ vers: [String],_ addr: String,_ fn: @escaping FnCallback){
        
        self.addr = addr
        self.vers = vers
        
        let group = DispatchGroup()
        for ver in vers{
            group.enter()
            getEach(ver,{group.leave()})
        }
        
        group.notify(queue: .main){
            let datas = self.mergeDiffVers()
            let titles = self.gTitle()
            fn(titles, datas) // async finish
        }
    }
    /// self.datas dictionary 有不同版本的結果, 但兩個要結合
    private func mergeDiffVers()->[[DOneLine]]{
        // output: [[DOneLine]] = []
        // re[0][0]，re[0][1] 分別為 [0]版本的[0]節，[1]版本的[0]節
        // re.count 就是總節數， re[j].count 是版本數
        // ESV, 和合本，於 太18 是特例，馬可最後一章也有
        
        // 流程1，計算此次全部會共有幾節。並形成 dict，在第2步的時候要知道自己該寫入 哪個 row。
        let cntVer = datas.count // 方便用
        
        let datas2 = datas.map { (key: String, value: [DOneLine]) in
            return value.map({($0,DAddresses($0.addresses2!))})
        }
        let addressAll = datas2.map({$0.map({$0.1})}).flatMap({$0})
        let addressDistinctOrder = sinq(addressAll).distinct({$0==$1}).orderBy({$0}).toArray()
        
        let cntVerse = addressDistinctOrder.count // 方便用
        
        // 預備 dict
        var dictAddress2Row: [Int:Int] = [:] // DAddresses 必須要有 Hashable, 這是為何不用  [DAddresses:Int]
        for i in ijnRange(0, addressDistinctOrder.count){
            let a1 = addressDistinctOrder[i]
            dictAddress2Row[a1.hashNumber()] = i
        }
        // assert ( dictAddress2Row.count == addressDistinctOrder.count )
        
        // 流程2: 產生 output，先產生一個 grid，再放入指定 row。
        var re = ijnRange(0, cntVerse).map({_ in Array(repeating: DOneLine(), count: cntVer)}) // 產生1個空的
        for i1 in ijnRange(0, datas2.count){
            let a1 = datas2[i1]
            for a2 in a1 {
                let hash = a2.1.hashNumber()
                if let row = dictAddress2Row[hash] {
                    re[row][i1] = a2.0
                }
            }
        }
        return re
    }
    private func gTitle()->[DOneLine]{
        return vers.map({ a1 in
            let r1 = DOneLine()
            r1.children = [DText(a1)]
            return r1
        })
    }
    private func getEach(_ ver: String,_ fn: @escaping ()->Void){
        
        bibleG.queryAsync(ver, addr, { re in
            self.datas[ver] = re
            fn()
        })
    }
}
