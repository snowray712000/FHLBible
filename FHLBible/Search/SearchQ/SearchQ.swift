//
//  SearchQ.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/13.
//

import Foundation

class DSearchParameters {
    /// [uvn, kjv]
    var vers: [String]! = ["unv"]
    /// G3142, H3142, '摩西 亞倫', '摩西'
    var keywords: String!
    /// 1 or nil
    var gb: Int? = { ManagerLangSet.s.curIsGb ? 1 : 0}()
    /// 在預設分類時, 要用到
    var addr: DAddress! = DAddress(1,1,1)
}
class DSearchResult{
    /// 最原本的資料
    var datas: [DAddress]!
    /// classor name, cnt
    var cntClassor: [String:Int] = [:]
    /// bookId (1-based, cnt)
    var cntBook: [Int:Int] = [:]
    /// 若是 nil, 表示沒有建議 分類 (數量很多的時候會這樣)
    var suggestClassor: String?
    /// 若是 nil, 表示沒有建議 書卷
    var suggestBook: Int?
}
protocol ISearchQ {
    func mainAsync(_ param: DSearchParameters)
    var onSearchResultFinished$: IjnEventOnceAny { get }
    /// 某版本, 多少個
    var onProgressChanged$: IjnEvent<String,Int> { get }
    var searchResult: DSearchResult? { get }
    var progress: [String:Int] {get}
    var status: SearchQ.TpStatus {get}
}
class SearchQ : NSObject , ISearchQ {
    func mainAsync(_ param: DSearchParameters){
        self._param = param
        if _param.keywords == nil || _param.keywords!.isEmpty {
            _status = .parameter_error
            self.onProgressChanged$.trigger(nil, nil)
            return
        }
        
        let help1 = KeywordHelper()
        help1.main(_param.keywords)
        
        let help2 = VersionHelper()
        let vers = help2.main(_param.vers, help1.isSN)
        
        vers.forEach({_progress[$0]=0}) // reset count
    
        let gp = DispatchGroup()
        
        let help3s = _versReal.map({QuerySeDataHelper($0,help1)})
        help3s.forEach { a1 in
            a1.onTick$.addCallback { sender, pData in
                self._status = .querying
                self._progress[a1.ver] = a1.datas.count
                self.onProgressChanged$.trigger(a1.ver, a1.datas.count)
            }
            a1.onFinish$.addCallback { sender, pData in
                self._dataEachVer[a1.ver] = a1.datas
                gp.leave()
            }
            gp.enter()
            a1.mainQAsync()
        }
        
        gp.notify(queue: .main) {
            self._merge() // merge 多版本位置 re.datas
            self._searchResult = self._generateResultAfterMerge()
            self._status = .finished
            self.onSearchResultFinished$.triggerAndCleanCallback()
        }
    }
    /// 所有事都完成了, 可以使用 searchResult getter (原本叫 onCounted )
    var onSearchResultFinished$: IjnEventOnceAny = IjnEventOnce()
    /// progress$ 用，可以不用。(原本規劃叫 onTicked)
    var onProgressChanged$: IjnEvent<String,Int> = IjnEvent()
    
    var _param: DSearchParameters!
    var searchResult: DSearchResult? { _searchResult }
    var _searchResult: DSearchResult?
    var progress: [String:Int] { _progress }
    /// 每個版本，目前數量
    var _progress: [String:Int] = [:]
    var _versReal: [String] {
        return _progress.keys.map({$0})
    }
    var _dataEachVer: [String:[DAddress]] = [:]
    
    var _mergeDataMergedAndOrdered:[DAddress]!
    func _merge(){
        if _versReal.count == 1{
            // 預設它的回傳就是按順序
            _mergeDataMergedAndOrdered = _dataEachVer.first!.value
        } else {
            var r1: Set<DAddress> = Set()
            _dataEachVer.forEach({r1.ijnAppend(contentsOf: $0.value)})
            _mergeDataMergedAndOrdered = r1.sorted(by: <)
        }
    }
    enum TpStatus {
        /// 參數不對, 不足
        case parameter_error
        case querying
        case finished
    }
    var status: TpStatus { _status }
    var _status: TpStatus = .parameter_error
    private func _generateResultAfterMerge()->DSearchResult {
        let re = DSearchResult() // 產生結果
        // 所有資料
        re.datas = self._mergeDataMergedAndOrdered
        
        // 計算統計結果 (每卷書的數量)
        let countHelper = CountHelper()
        countHelper.mainCount(self._mergeDataMergedAndOrdered, self._param.gb == 1)
        re.cntBook = countHelper.cntBook
        re.cntClassor = countHelper.cntClassor
        
        // 建議書卷
        let suggestHelper = SuggestHelper()
        suggestHelper.mainSuggest(self._param.addr.book, re.cntBook, re.cntClassor, self._param.gb == 1)
        re.suggestBook = suggestHelper.resultBook
        re.suggestClassor = suggestHelper.resultClassor
        
        return re
    }
}

/// 透過關鍵字，來判斷是 sn 還是 keyword
/// 在產生每個版本之前，這必需先知道，因為若是 sn，只有 kjv unv 有 sn 可以用
fileprivate class KeywordHelper {
    func main(_ str: String){
        _keyword = str
        
        let helper = SnHelper()
        helper.main(_keyword)
        _sn = helper.sn
        _tp = helper.snTp
    }
    /// 原本的值
    private var _keyword: String!
    /// 若是 sn 會把數字解析出來
    private var _sn: String?
    /// 若是 sn，它是 tp 什麼？是  G 或 H
    private var _tp: String?
    
    /// 判斷是不是 Hebrew Or Greek Sn (這會影響版本)
    var isSN: Bool {
        return _sn != nil
    }
    /// 搭配 se.php 的參數 getter
    var orig: Int {
        if _tp == "G" { return 1 }
        if _tp == "H" { return 2 }
        return 0
    }
    /// 若是 sn, 會傳 sn 數字不含 H G,
    /// 其它, 傳原本的 keyword
    var keyword: String {
        if isSN { return _sn! }
        return _keyword
    }
}

fileprivate class VersionHelper {
    func main(_ vers:[String],_ isSn: Bool)->[String]{
        if isSn == false { return vers }
        
        let r1 = vers.filter({Self.snOnly.contains($0)})
        if r1.count == 0 { return ["unv"] }
        return r1
    }
    static var snOnly = ["unv","kjv"]
}

/// SearchQ 還要整合不同的小事件
/// 所以這個獨立出來，專心作抓取，「抓取不夠，再發起抓起」這事。
fileprivate class QuerySeDataHelper {
    init(_ ver: String, _ keyHelper:KeywordHelper){
        self._ver = ver
        self._keyhelp = keyHelper
    }
    /// 外部會用，內部也有用。
    var onTick$: IjnEventAny = IjnEvent()
    var onFinish$: IjnEventOnceAny = IjnEventOnce()
    var datas: [DAddress] { _datas }
    var ver: String { _ver }
    private var _datas: [DAddress] = []
    private var _ver: String!
    private var _keyhelp: KeywordHelper!
    /// 完成1次 se 時, 會設定其值 (若不等於 500, 會設為 false )
    /// 若 api 失敗, 也會設為 false
    private var _isContinue = true

    func mainQAsync(){
        _datas.removeAll()
        
        self.onTick$.addCallback { sender, pData in
            if self._isContinue {
                self.doOnceAsyncAndTriggerTicked()
            } else {
                self.onFinish$.triggerAndCleanCallback()
            }
        }
        
        doOnceAsyncAndTriggerTicked()
    }
    private func cvt(_ a1: DApiSe.OneRecord)->DAddress {
        let r1 = BibleBookNameToId().main1based(.Matt, a1.engs!)
        return DAddress(r1, a1.chap!, a1.sec!)
    }
    private func gParam()->String {
        let offset = _datas.count
        let orig = _keyhelp.orig
        let range = orig
        let q = _keyhelp.keyword
        let gb1 = ManagerLangSet.s.curQueryParamGb
        return "index_only=1&limit=500&offset=\(offset)&orig=\(orig)&RANGE=\(range)&q=\(q)&VERSION=\(_ver!)&\(gb1)"
    }
    
    fileprivate func doOnceAsyncAndTriggerTicked() {
        // index_only=1&limit=500&offset=0&orig=2&RANGE=2&q=430&VERSION=unv
        // index_only=1&limit=500&offset=500&orig=2&RANGE=2&q=430
        let param = gParam()
        print (param)
        fhlSe(param) { data in
            if data.isSuccess() == false {
                self._isContinue = false
            } else {
                if data.record.count != 500 {
                    self._isContinue = false
                }
                if data.record.count != 0 {
                    self._datas.append(contentsOf: data.record.map({self.cvt($0)}))
                }
            }
            
            self.onTick$.trigger() // 不論正常與否，都 tick 一下
        }
    }
}

/// 統計用
fileprivate class CountHelper {
    /// classor name, cnt
    var cntClassor: [String:Int] = [:]
    /// bookId (1-based, cnt)
    var cntBook: [Int:Int] = [:]
    
    var _data: [DAddress]!

    
    func mainCount(_ data:[DAddress],_ isGb:Bool){
        self._data = data
        
        countEachBook()
        
        countClassor(isGb)
    }
    private func countEachBook(){
        let r1 = Dictionary(grouping: _data, by: {$0.book})
        for a1 in r1 {
            cntBook[a1.key] = a1.value.count
        }
    }
    fileprivate func countClassor(_ isGb: Bool) {
        let r1 = isGb ? BibleBookClassor._dictNa2CntGB : BibleBookClassor._dictNa2Cnt
        for a1 in r1 {
            let r2: [Int] = a1.value.map({self.cntBook[$0]}).filter({$0 != nil}) as! [Int]
            let sum = r2.reduce(0, +)
            if sum != 0 {
                cntClassor [a1.key] = sum
            }
        }
    }
}
/// 計算 suggest
fileprivate class SuggestHelper {
    private let _isCountLimit = 10 // 至少 24 個
    var resultBook: Int?
    var resultClassor: String?
    
    func mainSuggest(_ idBookCur:Int,_ cntbook:[Int:Int],_ cntclassor: [String: Int],_ isGb:Bool){
        let r1 = cntbook[idBookCur] ?? 0
        
        if r1 > _isCountLimit {
            resultBook = idBookCur
            return
        }
        
        let dict1 = isGb ? BibleBookClassor._dictNa2CntGB : BibleBookClassor._dictNa2Cnt
        let r2 = dict1.sorted { a1, a2 in
            return a1.value.count < a2.value.count
        }.filter({$0.value.contains(idBookCur)})
        
        for a2 in r2 {
            if cntclassor[a2.key] ?? 0 > _isCountLimit {
                resultClassor = a2.key
                return
            }
        }
        
        resultClassor = "全部" // 繁體、簡體，剛好這兩個字一樣
        return
    }
}
