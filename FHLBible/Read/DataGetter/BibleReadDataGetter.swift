//
//  File.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/9/10.
//

import Foundation

/// 為了 BibleReadDataGetter
protocol IBibleGetter {
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
        self.bibleG = BibleGetterViaFhlApiQsb()
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
        // 隨便合，管它的經節如何 (不一樣多，順序，合併上節之類的)
        var re:[[DOneLine]] = []
        
        let cntVer = datas.count
        let cnt = datas.map({$0.value.count}).max()!
        let datas2 = (0..<cntVer).map({datas[vers[$0]]!})
        
       
        // cnt 會等於節數
        for i in 0..<cnt {
            var re2: [DOneLine] = []
            
            for j in 0..<cntVer {
                let r3 = datas2[j]
                let r4 = i < r3.count ? r3[i] : DOneLine()
                re2.append(r4)
            }
            
            re.append(re2)
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


