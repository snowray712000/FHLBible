//
//  VCSearchResults.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/27.
//

import Foundation
import UIKit

class VCSearchResult : UIViewController {
    func setInitData(_ keyword: String,_ vers:[String],_ addr:DAddress!){
        self._keyword = keyword
        self._vers = vers
        self._addr = addr
        
        // search result 的 sn 設定，不要用到全域，全域的用在 read
        self._isSn =  { let r1 = SnHelper()
            r1.main(keyword)
            return r1.sn != nil
        } ()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 繪圖
        _onSearchResultChanged$.addCallback { sender, pData in
            self._drawTitle() // 前一刻變「搜尋中...」了
            self._cvtForFilters()
            self._drawFilterView()
            self._updateDataForTableWhenOptCurChanged()
            self._drawDataView()
        }
        _isSnOnChanged$.addCallback { sender, pData in
            self._drawDataView()
        }
        // 進度列目前沒有實作
        //_onSearchTick$.addCallback { sender, pData in
        //    print (pData)
        //    print ( sender!.progress )
        //} 
        self.viewSearchFilter.onClickFilterOption$.addCallback { sender, pData in
            self._optCur = pData!.na
            self._groupCur = pData!.na2
            self._updateDataForTableWhenOptCurChanged()
            self._drawDataView()
        }
        
        /// 點擊內容時 (內容有可能有交互參照，又或著是 SN)
        let isNotNil = { (pData: ViewDisplayTable2.OneEvent?)-> Bool in
            return pData != nil && pData!.dtext != nil
        }
        // 點擊 SN 時
        self.viewSearchData.onClickDatas$.addCallback { sender, pData in
            if isNotNil(pData) && pData!.dtext!.sn != nil {
                let addr = self._getAddrOfThisRow(pData!.row)
                if addr == nil { return }
                SnDTextClickFlow(vc: self, addr: addr!, vers: self._vers).mainAsync(pData!.dtext!)
            }
        }
        // 點擊 Ref 時
        self.viewSearchData.onClickDatas$.addCallback { sender, pData in
            if isNotNil(pData) && pData!.dtext!.refDescription != nil && pData!.col != -1 {
                RefDTextClickFlow(vc: self, addr: self._addr, vers: self._vers).mainAsync(pData!.dtext!)
            }
        }
        // 點擊到 【231】注腳時
        self.viewSearchData.onClickDatas$.addCallback { sender, pData in
            if isNotNil(pData) && pData!.dtext!.foot != nil && pData!.col != -1 && pData!.row != -1 && self._dataForTable != nil{
                // 預備參數, 某 row 的 addr
                let addr = self._getAddrOfThisRow(pData!.row)
                if addr == nil { return }
                
                // 預備參數, 某 col 的 ver
                let col = pData!.col
                let ver = self._vers[col]
                
                let flow =  FooterDTextClickFlow(vc: self, vers: self._vers)
                flow.mainAsync(pData!.dtext!, ver, addr!)
            }
        }
        
        // 點擊 節 時
        self.viewSearchData.onClickDatas$.addCallback { sender, pData in
            if isNotNil(pData) && pData!.col == -1 {
                let flow = OneVerseFunctionsClickFlow(vc: self, addrThisPageFirst: self._addr, vers: self._vers)
                flow.mainAsync(pData!.dtext)
            }
        }
        
        self._drawTitle()
        self._drawFilterView()
        _searchAsync()
        
        self._drawButtonSNState()
    }
    @IBOutlet var viewSearchFilter: ViewSearchFilter!
    @IBOutlet var viewSearchData: ViewDisplayTable2!
    /// 為了作，「當版本不含 和合本、和合本2010、KJV」時，將其 disalbe
    @IBOutlet var btnSN: UIButton!
    func _drawButtonSNState(){
        drawSnButtonState(btn: self.btnSN, vers: self._vers)
    }
    var _isSn: Bool! = false // 隨便一個變數，當 set 時會設定
    @IBAction func doSwitchSn(){
        _isSn = !_isSn
        self._isSnOnChanged$.trigger()
    }
    var _isSnOnChanged$: IjnEventAny = IjnEvent()
    
    var _keyword: String!
    func _drawTitle(){ self.title = _keyword }
    var _vers: [String]!
    func _versGenerateForDTexts()->[DText] {
        return _vers.map({DText(BibleVersionConvertor().na2cna($0))})
        
    }
    var _addr: DAddress!
    
    func _gOneISearchQ( )-> ISearchQ { SearchQ() }
    
    var _searchResult: DSearchResult?
    var _onSearchResultChanged$: IjnEventAny = IjnEvent()
    var _onSearchTick$: IjnEvent<ISearchQ,Any> = IjnEvent()
    
    /// 某書卷或分類 (可能是簡體) 在 search 後會設定的，用此繪圖 viewFilter
    var _optCur:String?
    /// 書卷|分類, 在 search 後會設定的，用此繪圖 viewFilter
    var _groupCur:String?
    /// 在 search 後會設定的，用此繪圖 viewFilter
    var _filtersOptions: [SearchData.Filter]?
    
    func _searchAsync(){
        // 搜尋中 訊息
        self.title = "搜尋中..."
        
        // 開始搜尋
        let pa = DSearchParameters ()
        pa.keywords = _keyword
        pa.addr = _addr
        pa.vers = _vers
        
        let se = _gOneISearchQ()
        se.onSearchResultFinished$.addCallback { sender, pData in
            if se.status == .parameter_error {
                fatalError("搜尋參數錯誤")
            } else {
                self._searchResult = se.searchResult
                self._onSearchResultChanged$.trigger()
            }
        }
        se.onProgressChanged$.addCallback { sender, pData in
            self._onSearchTick$.trigger(se,(ver:sender, cnt:pData))
        }
        se.mainAsync(pa)
    }
    func _drawFilterView(){
        viewSearchFilter.setInitData(self._filtersOptions, self._optCur, self._groupCur)
    }
    func _drawDataView(){
        let r1 = _versGenerateForDTexts()
        let r1a = r1.map({[$0]})
       
        let isOpenHanBibleTCs = _vers.map({["ttvh","thv12h","ttvhl2021"].contains($0)})
        let tpTextAlignment = getTpTextAlignmentsViaBibleVersions(_vers)
        
        viewSearchData.setInitData(_dataForTable!, ([],r1a), _isSn, isOpenHanBibleTCs, tpTextAlignment)
    }
    func _cvtForFilters(){
        let r1 = _searchResult!
        
        let r2a: BookNameLang = ManagerLangSet.s.curTpBookNameLang
        let r2 = BibleBookNames.getBookNames(r2a)
        
        // for filters parameter
        // var re: [String:Int] = [:]
        
        var reFilters = r1.cntBook.sorted { a1, a2 in
            return a1.key < a2.key
        }.map { (key: Int, value: Int) -> SearchData.Filter in
            let na = r2[key-1] // bookId - 1
            return SearchData.Filter(na, value, "書卷")
        }
        
        let re2 = ManagerLangSet.s.curBookClassorNaOrder.map { a1 -> SearchData.Filter in
            let r2 = r1.cntClassor[a1]
            return SearchData.Filter(a1, r2 ?? 0, "分類")
        }.filter({$0.cnt > 0})
        
        reFilters.append(contentsOf: re2)
        
        let reGp = r1.suggestClassor == nil ? "書卷" : "分類"
        let opt = r1.suggestClassor == nil ? r2[r1.suggestBook! - 1] : r1.suggestClassor!
        
        // output this function
        self._optCur = opt
        self._groupCur = reGp
        self._filtersOptions = reFilters
    }
    
    /// --> _searchResult
    var _addressAll: [DAddress] { _searchResult!.datas }
    /// --> _searchResult
    var _datasCache: [DAddress: [[DText]]]? = [:]
    var _dataForTable: DataForDrawTable?
    func _updateDataForTableWhenOptCurChanged(){
        func getFilterAddress ()->[DAddress] {
            func getBookCase()->[DAddress]{
                let tp = ManagerLangSet.s.curTpBookNameLang
                let idbook = BibleBookNameToId().main1based(tp, self._optCur!)
                return _searchResult!.datas.filter({$0.book == idbook})
            }
            func getClassorCase() ->[DAddress]{
                let r1 = ManagerLangSet.s.curBookClassor
                let r2 = r1.first(where: {$0.key == self._optCur!})
                if r2 == nil { return [] }
                
                return _searchResult!.datas.filter({r2!.value.contains($0.book)})
            }
            // 函式主體 getFilterAddress
            if self._groupCur == "分類" {
                return getClassorCase()
            } else {
                return getBookCase()
            }
        }
        
        // 函式主體 _updateDataForTableWhenOptCurChanged
        if _dataForTable != nil {
            _dataForTable!.isAlreadyNoUse = true
        }
        
        _dataForTable =  DataForDrawTable(_vers, getFilterAddress(),_colorKeyword)
    }
    func _colorKeyword(_ dataOneRow: ViewDisplayTable2.OneRow) {
        let snHelper = SnHelper()
        
        func doWhenSn(){
            func doDts(_ dts:[DText]){
                for a1 in dts{
                    if a1.children != nil {
                        doDts(a1.children!)
                    } else {
                        if a1.sn == snHelper.sn && a1.tp == snHelper.snTp {
                            a1.keyIdx0based = 0
                        }
                    }
                }
            }
            for i in 0..<_vers.count {
                if i >= dataOneRow.datas.count{
                    continue
                }
                
                let r1 = dataOneRow.datas[i]
                if ["unv","kjv"].contains(_vers[i]){
                    // 只有這2個版本才會有 sn
                    doDts(r1)
                }
            }
        }
        func doWhenKeywork() throws {
            // 核心，可看 testSearchKeyword
            let r1 = snHelper.keyword.split(separator: " ")
            let r2 = r1.map({"(\($0))"}).joined(separator: "|")
            let r3 = try NSRegularExpression(pattern: r2, options: [.caseInsensitive])
            
            func doDtext(_ dt: DText){
                // assert ( dt.children == nil )
                if dt.isCantSplit() { return }
                
                let r1 = SplitByRegex().main(str: dt.w!, reg: r3)
                if r1 == nil { return }
                
                func gDts()->[DText] {
                    var re:[DText] = []
                    for a1 in r1! {
                        if a1.isMatch() == false {
                            let r2 = dt.clone()
                            r2.w = String(a1.w)
                            re.append(r2)
                        } else {
                            var idx: Int {
                                for i in 1..<a1.exec.count {
                                    if a1.exec[i] != nil { return i }
                                }
                                return 0 // 雖然不可能，但還是給它一個預設值吧
                            }
                            
                            let r2 = dt.clone()
                            r2.w = String(a1.w)
                            re.append(r2)
                            
                            r2.keyIdx0based = idx - 1
                            if r2.keyIdx0based == -1 { r2.keyIdx0based = 0}
                        }
                    }
                    return re
                }
                
                dt.children = gDts()
                dt.w = nil
                dt.tpContain = ""
            }
            func doDTexts(_ dts:[DText]){
                for a1 in dts {
                    if a1.children != nil {
                        doDTexts(a1.children!)
                    } else {
                        doDtext(a1)
                    }
                }
            }
            
            for a1 in dataOneRow.datas {
                doDTexts(a1)
            }
        }
        
        snHelper.main(_keyword)
        if snHelper.sn != nil {
            doWhenSn()
        } else {
            try! doWhenKeywork()
        }
    }
    private func _getAddrOfThisRow(_ row:Int)->DAddress?{
        // 預備參數, 某 row 的 addr
        let dataT = self._dataForTable!
        let r1 = dataT._datas // dict
        let r2 = r1[row]
        if r2 == nil { return nil }
        let r3 = r2!.0.map({$0.w ?? "" }).joined(separator: "")
        let r4 = StringToVerseRange().main(r3, (self._addr.book, self._addr.chap))
        if r4.count == 0 { return nil }
        return r4.first!
    }
}

