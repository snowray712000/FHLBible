import Foundation
import UIKit
import AVFoundation

protocol IVCReadDataQ {
    func qDataForReadAsync(_ addr:String, _ vers: [String])
    var qDataForRead$: IjnEventOnce<Any,(ViewDisplayTable2.OneRow,[ViewDisplayTable2.OneRow])> { get }
}
/// 呼叫 setInitData 後再開啟此
class VCRead : UIViewController, IEventsHelperOfTableOfRead {

    /// drawTitle()  -> addrs
    /// updateData() -> addrs, vers
    /// drawData ->  datas
    override func viewDidLoad() {
        
        super.viewDidLoad()
        eventsTableHelper = EventsHelperOfTableOfRead(self)
        
        self._swipeHelp.addSwipe(dir: .left)
        self._swipeHelp.addSwipe(dir: .right)
        self._swipeHelp.addSwipe(dir: .right, numberOfTouches: 2)
        self._swipeHelp.addSwipe(dir: .right, numberOfTouches: 3)
        self._swipeHelp.onSwipe$.addCallback { sender, pData in
            if pData!.direction == .left {
                self.goNext()
            } else if pData!.direction == .right {
                if pData?.numberOfTouchesRequired == 1 {
                    self.goPrev()
                } else if pData?.numberOfTouchesRequired == 2{
                    self.clickGoBack()
                } else if pData?.numberOfTouchesRequired == 3 {
                    self.pickFromHistory()
                }
            }
        }

        
        // 經文內容 dependen on ...
        _addrsCurChanged$.addCallback { sender, pData in
            self.drawTitle()
            self.updateData()
        }
        _versChanged$.addCallback { sender, pData in
            self._drawButtonSNState()
            self.updateData()
        }
        _dataChanged$.addCallback { sender, pData in
            self.drawData()
        }
        _isSnOnChanged$.addCallback { sender, pData in
            self.drawData()
        }
        
        // 維護 全域變數
        _addrsCurChanged$.addCallback { sender, pData in
            ManagerAddress.s.updateCur( self._addrsCur! )
        }
        _versChanged$.addCallback { sender, pData in
            ManagerBibleVersions.s.updateCur(self._vers)
        }
        _addrsCurChanged$.addCallback { sender, pData in
            if self._isTriggerByGoBack == false {
                self._addToReadHistory()
                
                self._idxGoBack = 0 // reset
            } else {
                self._isTriggerByGoBack = false
            }
        }
        _isSnOnChanged$.addCallback { sender, pData in
            ManagerIsSnVisible.s.updateCur(self._isSnVisible)
        }
        
        // 點擊內容時的動作
        listenEventsWhenInit()

        // 開始
        drawTitle()
        updateData()
        eventsTableHelper.starting()
                
        self._drawButtonSNState()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        // 當交互參照 push 後，再 back 時，要再把 history 換到目前變第1個
        self._addToReadHistory()
        _idxGoBack = 0
    }
    lazy var _swipeHelp = SwipeHelp(view: self.view)
    
    var _isViewDidLoadAlready = false
    /// 為了作，「當版本不含 和合本、和合本2010、KJV」時，將其 disalbe
    @IBOutlet var btnSN: UIButton!
    func _drawButtonSNState(){
        drawSnButtonState(btn: self.btnSN, vers: self._vers)
    }
    @IBOutlet weak var viewDisplayTable: UIView!
    @IBOutlet var btnTitle: UIButton!
    /// 供還沒顯示前呼叫, 它不會去 trigger
    /// vers是設 [unv, cnv] 這些
    func setInitData(_ addr:VerseRange,_ vers:[String]){
        self._addrsCur = addr
        self._vers = vers
        if vers.count == 0 {
            self._vers = ["unv"]
        }
    }
    /// nil 的時候，會用 _addrsCur!.verses
    fileprivate func _addToReadHistory(_ addr:String? = nil){
        let addr2 = addr ?? VerseRangeToString().main(self._addrsCur!.verses, ManagerLangSet.s.curTpBookNameLang )
        var r2 = ManagerHistoryOfRead.s.cur
        
        // 防止重複，但又不用 remove where 是提高效率
        let r2a = r2.ijnIndexOf(addr2)
        if r2a != nil { r2.remove(at: r2a!) }
        
        r2.insert(addr2, at: 0)
        ManagerHistoryOfRead.s.updateCur(r2)
    }
    
    
    @IBAction func doMore(){
        let vc = VCReadMore()
        vc.onPicker$.addCallback { sender, pData in
            if pData == "prev" {
                self.goPrev()
            } else if pData == "next" {
                self.goNext()
            } else if pData == "back" {
                self.clickGoBack()
            } else if pData == "history" {
                self.pickFromHistory()
            } else if pData == "audiobible" {
                let vc = self.gVCAudioBible()
                let addr = self._addrsCurFirst!
                vc.book = addr.book
                vc.chap = addr.chap
                self.navigationController?.pushViewController(vc, animated: true)
            } else if pData == "audiobibletext" {
                let vc = self.gVCAudioTextBible()
                vc.addr = self._addrsCur!
                vc.vers = self._vers
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }

        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = vc

        present(vc,animated: true,completion: nil)
        
    }
    @IBAction func switchSnVisible(){
        if _isSnVisible {
            _isSnVisible = false
            _isSnOnChanged$.trigger()
        } else {
            _isSnVisible = true
            _isSnOnChanged$.trigger()
        }
    }
    lazy var _isSnVisible : Bool = ManagerIsSnVisible.s.cur
    var _isSnOnChanged$: IjnEventAny = IjnEvent()
    @IBAction func goNext(){
        _addrsCur = _addrsCur!.goNext()
        _addrsCurChanged$.trigger(nil, nil)
    }
    @IBAction func goPrev(){
        _addrsCur = _addrsCur!.goPrev()
        _addrsCurChanged$.trigger(nil, nil)
    }
    
    var _addrsCur: VerseRange? = nil
    var _addrsCurChanged$: IjnEventAny = IjnEvent()
    fileprivate var _addrsCurFirst: DAddress? {
        if _addrsCur == nil || _addrsCur!.verses.count == 0 {
            return nil
        }
        return _addrsCur!.verses.first!
    }
    fileprivate var _titleAddr: String {
        if _addrsCur == nil || _addrsCur!.verses.count == 0 { return ""}
        return VerseRangeToString().main(_addrsCur!.verses, ManagerLangSet.s.curTpBookNameLang)
    }
    
    /// _addrsCurChanged$
    private func drawTitle(){
        btnTitle.setTitle(_titleAddr, for: .normal)
    }
    
    var _vers: [String] = ["unv","kjv"]
    var _versChanged$:IjnEventAny = IjnEvent()
    
    typealias TpOneRow = ViewDisplayTable2.OneRow
    /// 中繼資料, addr 改變時, versions 改變時, 都要去改變
    fileprivate var _data: (title: TpOneRow, data: [TpOneRow])?
    fileprivate var _dataChanged$: IjnEvent<Any,Any> = IjnEvent()
    /// 當 addr 或 versions 改變後, 呼叫此
    /// 此，也會 trigger 中繼資料 _data Changed$
    fileprivate func updateData(){
        // 當網路慢的時候，很重要
        let iQQueryingState: IVCReadDataQ = ReadDataDataQuerying()
        iQQueryingState.qDataForRead$.addCallback { sender, pData in
            self._data = (pData!.0, pData!.1)
            self._dataChanged$.trigger()
        }
        iQQueryingState.qDataForReadAsync(_titleAddr, _vers)
        
        // 正式抓資料
        let iDataQ: IVCReadDataQ = ReadDataQ()
        iDataQ.qDataForRead$.addCallback { sender, pData in
            self._data = (title: pData!.0, data: pData!.1)
            self._dataChanged$.trigger(nil, nil)
        }
        iDataQ.qDataForReadAsync(_titleAddr, _vers)
    }
    fileprivate func drawData(){
        let isOpenHanBibleTCs = BibleVersionFonts().mainIsOpenHanBibleTCs(_vers)
        let tpTextAlignment = getTpTextAlignmentsViaBibleVersions(_vers)
        self.v2.set(_data!.title, _data!.data, _isSnVisible, isOpenHanBibleTCs, tpTextAlignment)
    }
    
    
    private func getAddrCur()->DAddress? {
        if _addrsCur != nil {
            if _addrsCur!.verses.count != 0 {
                return _addrsCur?.verses.first!
            }
        }
        return nil
    }
    var v2: ViewDisplayTable2 { viewDisplayTable as! ViewDisplayTable2}
    var iVCRead: IVCRead { VCReadImplementEvents(v2, getVersion) }
    /// 按 GoBack 時，考慮連續按的時候，它就是一直往前
    /// 還需要配一個參數 isTriggerByGoBack，不然 trigger addr change 時，會遞迴
    var _idxGoBack = 0
    var _isTriggerByGoBack = false
    @IBAction func clickGoBack(){
        let r1 = ManagerHistoryOfRead.s.cur
        _idxGoBack = _idxGoBack + 1
        if _idxGoBack >= r1.count {
            _idxGoBack = _idxGoBack - 1
        } else {
            _addrsCur = VerseRange( StringToVerseRange().main(r1[_idxGoBack]) )
            _isTriggerByGoBack = true
            _addrsCurChanged$.trigger()
        }
    }
    func getVersion()->[String]{
        return _vers
    }

    @IBAction func pickBookChap(){
        // 準備「目前的」給 dialog 初始參數
        var fnCurAddr:(Int,Int) {
            if _addrsCur == nil || _addrsCur!.verses.isEmpty {
                return (1,1)
            } else {
                let r1 = _addrsCur!.verses.first!
                return (r1.book,r1.chap)
            }
        }
        let curAddr = fnCurAddr
        
        // 開始 push 到 dialog
        let r1 = self.gVCBookChapPicker()
        r1.initBeforePushVC(curAddr.0, curAddr.1)
        r1.onClick$.addCallback { sender, pData in
            let r2 = VerseRange()
            r2.verses = DAddress(book: pData!.idBook, chap: pData!.idChap, verse: 1, ver: nil).generateEntireThisChap()
            self._addrsCur = r2
            self._addrsCurChanged$.trigger(nil, nil)
            //let r2 = BibleBookNames.getBookName(pData!.idBook, .太)
            //self.btnTitle.setTitle("\(r2) \(pData!.idChap)", for: .normal)
        }
        navigationController?.pushViewController(r1, animated: false)
    }
    @IBAction func pickFromHistory(){
        let vc1 = self.gVCReadHistory()
        vc1.onClickAddr$.addCallback { sender, pData in
            if pData != nil {
                let r1 = VerseRange(StringToVerseRange().main(pData!))
                self._addrsCur = r1
                self._addrsCurChanged$.trigger()
            }
        }
        navigationController?.pushViewController(vc1, animated: false)
    }
    @IBAction func doSearching(){
        let vc2 = self.gVCSearching()
        vc2.onClickSearching$.addCallback { sender, pData in
            let vc3 = self.gVCSearchResult() // pData '天使'
            vc3.setInitData(pData!.w!, self._vers, self._addrsCurFirst!)
            self.navigationController?.pushViewController(vc3, animated: false)
        }
        self.navigationController?.pushViewController(vc2, animated: false)
    }
    
    /// 於 dialog 結束, 並且不是按取消 #譯本
    fileprivate func onFinishVersionPickor(_ vers:[String]){
        self._vers = vers
        self._versChanged$.trigger(nil, nil)
    }
    /// call by listenEventsWhenInit #譯本
    fileprivate func addListenForVersionsPicker(){
        iVCRead.onClickVersions$.addCallback { sender, pData in
            // 情境: 雖然按 okay, 但其實版本沒變, (順序、內容), 就不要再取一次
            let verOld = self._vers
            func isChanged(_ vers:[String])->Bool {
                if vers.count != verOld.count {
                    return true
                }
                return ijnRange(0, vers.count).ijnAny({verOld[$0] != vers[$0]})
            }
            
            // 原流程
            if pData != nil {
                let vc1 = self.gVCVersionsPicker()
                vc1.setInitData(self._vers)
                vc1.onClickOkay$.addCallback { sender, pData in
                    if pData != nil {
                        if isChanged(pData!) {
                            self.onFinishVersionPickor(pData!)
                        }
                    }
                }
                self.navigationController?.pushViewController(vc1, animated: false)
            }
        }
    }
    private func addListenForClickedAddr(){
        v2.onClickDatas$.addCallback { sender, pData in
            if pData != nil && pData!.col == -1 && pData!.dtext != nil && pData!.dtext!.w != nil {
                let flow = OneVerseFunctionsClickFlow(vc: self, addrThisPageFirst: self._addrsCurFirst, vers: self._vers)
                flow.mainAsync(pData!.dtext)
            }
        }
    }

    /// IEventsHelperOfTableOfRead
    var pTable: ViewDisplayTable2 { v2 }
    /// IEventsHelperOfTableOfRead
    var pVers: [String] { self._vers }
    /// IEventsHelperOfTableOfRead
    var pDatas: (title: ViewDisplayTable2.OneRow, data: [ViewDisplayTable2.OneRow])? {
        self._data
    }
    /// IEventsHelperOfTableOfRead
    var eventsTableHelper: EventsHelperOfTableOfRead!
    private func doWhenSnDTextClickedForDicts(){
            if eventsTableHelper.pDText != nil {
                let vcSnDict = self.gVCSnDict()
                vcSnDict.setInitData(eventsTableHelper.pDText!, self._addrsCurFirst!, self._vers)
                self.navigationController?.pushViewController(vcSnDict, animated: false)
            }
        }
    private func _doWhenSnDTextClickedForList(_ dtext:DText){
        
        // 不可直接用 dtext.w! 因為可能會是 <G3212> 而非 G3212
        let keyword = dtext.tp! + dtext.sn!
        
        let vcSnSearch = self.gVCSearchResult()
        vcSnSearch.setInitData(keyword, _vers, _addrsCurFirst!)
        self.navigationController?.pushViewController(vcSnSearch, animated: false)
    }

    private func addListenForSnDTextClick(){
        v2.onClickDatas$.addCallback { sender, pData in
            // 判斷, 是 sn 嗎
            if pData != nil {
                let dtext = pData!.dtext
                if dtext != nil && dtext!.sn != nil {
                    // 準備參數 row 對應的 addr (取得此 row 比直接用 第 1 個 addr 還正確，考慮複合型 read，即 羅1:2;創1:3
                    let addr = self._getAddrThisRow(pData!.row)
                    if addr == nil { return }
                    
                    let r1 = SnDTextClickFlow(vc: self, addr: addr!, vers: self._vers)
                    r1.mainAsync(dtext!)
                }
            }
        }
    }
    private func _getAddrThisRow(_ row:Int)->DAddress? {
        let r1 =  eventsTableHelper.pAddrs
        if r1 == nil { return nil }
        if r1!.verses.count == 0 { return nil }
        return r1!.verses.first!
    }

    private func addListenForReferenceDTextClick(){
        v2.onClickDatas$.addCallback { sender, pData in
            // 判斷, 是 ref 嗎
            if pData != nil {
                let dtext = pData!.dtext
                if dtext != nil && dtext!.refDescription != nil && pData!.col != -1 {
                    RefDTextClickFlow(vc: self, addr: self._addrsCurFirst!, vers: self._vers).mainAsync(dtext!)
                }
            }
        }
    }
    private func _getVerOfCol(_ c0based: Int)->String?{
        let r1 = self._vers
        if c0based >= r1.count {
            return nil
        }
        
        return r1[c0based]
    }
    private func addListenForFootDTextClick(){
        v2.onClickDatas$.addCallback { sender, pData in
            if pData != nil {
                let dtext = pData!.dtext
                
                let verse = self.eventsTableHelper.pAddrs
                if verse == nil || verse!.verses.count == 0 { return }
                
                if dtext != nil && dtext!.foot != nil && pData!.col != -1 && pData!.row != -1{
                    
                    let addr = verse!.verses.first!
                    let ver = self._vers[pData!.col]
                    let r1 = FooterDTextClickFlow (vc: self, vers: self._vers)
                    r1.mainAsync(dtext!, ver, addr)
                }
            }
        }
    }
   
    /// 初始化 viewDidLoad 時呼叫
    private func listenEventsWhenInit(){
        addListenForVersionsPicker()

        addListenForClickedAddr()
        
        addListenForSnDTextClick()
        
        addListenForReferenceDTextClick()
        
        addListenForFootDTextClick()
    }
}


/// 這個是查詢前，把 data 設為 查詢資料中 ... 若網路慢的時候，要有這個
fileprivate class ReadDataDataQuerying : NSObject, IVCReadDataQ {
    func qDataForReadAsync(_ addr: String, _ vers: [String]) {
        // 版本.
        let r2 = vers.map({ BibleVersionConvertor().na2cna($0)})
        let r2a = r2.map({[DText($0,isParenthesesHW: true)]})
        let r5 = (header:[DText()],datas:r2a)
        
        // 資料.
        
        // 特例，所選的版本們，都沒有這裡的經文
        let r6 = self._gNoData(vers.count)
        self.qDataForRead$.triggerAndCleanCallback(nil, (r5, r6))        
    }
    
    private func _gNoData(_ cntVer:Int) -> [([DText],[[DText]])]{
        let r1 = [DText()]
        let r2 = ijnRange(0, cntVer).map({ _ in [DText(NSLocalizedString("取得資料中...", comment: ""))]})
        
        return [(r1,r2)]
    }
    var qDataForRead$: IjnEventOnce<Any, (ViewDisplayTable2.OneRow, [ViewDisplayTable2.OneRow])> = IjnEventOnce()
}

/// VCRead 整合所需功能，需要的東西
protocol IVCRead {
    /// 按下「節-表格中最左邊 col 那些」，以致進行 選取功能 「VCVerseActionPicker」
    var onClickAddr$: IjnEvent<UIView,DText> { get }
    var onClickVersions$: IjnEvent<UIView,DText> { get }
    var onClickContentDText$: IjnEvent<UIView,(dtext:DText,ver:String)> {get}
}

class VCReadTest1 : IVCRead {
    var onClickContentDText$: IjnEvent<UIView, (dtext: DText, ver: String)> = IjnEvent()
    
    var onClickAddr$: IjnEvent<UIView, DText> = IjnEvent()
    var onClickVersions$: IjnEvent<UIView, DText> = IjnEvent ()
    init(){
//        DispatchQueue.main.async {
//            sleep(2)
//            self.onClickAddr$.trigger(UIView(), DText("羅1:1"))
//        }
    }
}

/// 原本是閱讀的，但搜尋也要用到，所以重構出來。
func drawSnButtonState(btn:UIButton,vers: [String]){
    if vers.ijnAny({["unv","kjv","rcuv"].contains($0)}) {
        btn.isEnabled = true
        btn.alpha = 1
    } else {
        btn.isEnabled = false
        btn.alpha = 0.2
    }
}
