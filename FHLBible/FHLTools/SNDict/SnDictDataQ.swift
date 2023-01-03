import Foundation
import IJNSwift
import FMDB
/// 很多其實都需要這個, 但這個是在寫 SnDictDataQ 定義的
/// SnDictDataQ 需要 CBOL 與 Twcb 版本的轉換器
protocol IStr2DTextArray {
    func main(_ str:String)->[DText]
}
class Str2DTextArrayTest1 : IStr2DTextArray {
    func main(_ str: String) -> [DText] {
        return [DText(str)]
    }
}

/// VCDict -> this
/// this -> SnDictDataTwcbQ, SnDictDataCbolQ
/// this -> IStr2DTextArray
/// 這個關鍵在整合多執行緒同時查詢, 並其結果
class SnDictDataQ {
    
    /// 太多資訊可用，所以就不傳資料了
    /// 最終繪圖資料 resultContent
    /// 其它資料 resultTwcb resultCBOL
    var onFinishedQ$: IjnEventOnceAny = IjnEventOnce()
    /// dtext: 要查詢的 sn. 例子 tp: G sn:2532a.
    func main(_ dtext:DText){
        _icvtTWCBOld = DictTwcbOldConvertor()
        _icvtTWCBNew = DictTwcbNewConvertor()
        _icvtCBOLOld = DictCbolOldConvertor()
        _icvtCBOLNew = DictCbolNewConvertor()
        _icvtCBOLOldEn = DictCbolOldEnConvertor()
        _icvtCBOLNewEn = DictCbolNewEnConvertor()
        
        _dtext = dtext
        
        // 多個執行緒同步，幾個 enter, 就要幾個 leave
        let group = DispatchGroup()
        step1_startGroupEvents(group)
        group.notify(queue: .main){
            if self._dtext.snAction == .dict {
                self.step2a_mergeAllVersion()
            } else {
                self.resultContent = self._getResultWhereActionTp()
            }
            
            self.onFinishedQ$.triggerAndCleanCallback()
        }
        

    }
    
    /// 原始資料
    var errorCBOL: [DText]?
    var errorTwcb: [DText]?
    var resultCBOL: DApiSd?
    var resultTwcb: DApiSbdBase?
    var resultContent: [DText]! // 最後資料,繪圖用
    
    // helper functions
    private var _dtext: DText!
    private var _isCbol: Bool {
        let r1 = _dtext.snAction!
        return r1 == .dict || r1 == .cbol || r1 == .cbole
    }
    private var _isTwcb: Bool {
        let r1 = _dtext.snAction!
        return r1 == .dict || r1 == .twcb
    }
    private var _isOldTestment: Bool {
        return _dtext.tp == "H"
    }
    
    fileprivate func step1_startGroupEvents(_ group: DispatchGroup) {
        if self._isCbol {
            group.enter()
            //let r1 = SnDictDataCbolQOffline()
            //let r1 = SnDictDataCbolQ()
            let r1 = SnDictDataCbolQAuto()
            r1.onApiFinished$.addCallback { sender, pData in
                self.errorCBOL = sender // nil 表示沒資料
                self.resultCBOL = pData //
                group.leave()
            }
            r1.mainAsync(_dtext)
        }
        if self._isTwcb {
            group.enter()
            let r1 = SnDictDataTwcbQ()
            r1.onApiFinished$.addCallback { sender, pData in
                self.errorTwcb = sender
                self.resultTwcb = pData
                group.leave()
            }
            r1.main(_dtext)
        }
    }
    
    private lazy var _icvtTWCBOld: IStr2DTextArray = Str2DTextArrayTest1()
    private lazy var _icvtTWCBNew: IStr2DTextArray = Str2DTextArrayTest1()
    private lazy var _icvtCBOLOld: IStr2DTextArray = Str2DTextArrayTest1()
    private lazy var _icvtCBOLNew: IStr2DTextArray = Str2DTextArrayTest1()
    private lazy var _icvtCBOLOldEn: IStr2DTextArray = Str2DTextArrayTest1()
    private lazy var _icvtCBOLNewEn: IStr2DTextArray = Str2DTextArrayTest1()
    private lazy var _reDTextsCbol: [DText] =  {
        let icvt: IStr2DTextArray = _isOldTestment ? self._icvtCBOLOld : self._icvtCBOLNew
        
        return errorCBOL == nil ? icvt.main(self.resultCBOL!.record.first!.dic_text!) : errorCBOL!
    }()
    private lazy var _reDTextsCbolEn: [DText] =  {
        let icvt: IStr2DTextArray = _isOldTestment ? self._icvtCBOLOldEn : self._icvtCBOLNewEn
        
        return errorCBOL == nil ? icvt.main(self.resultCBOL!.record.first!.edic_text!) : errorCBOL!
    }()
    private lazy var _reDTextsTwcb: [DText] =  {
        let icvt: IStr2DTextArray = _isOldTestment ? self._icvtTWCBOld : self._icvtTWCBNew
        let r1 =  resultTwcb!.record.first!.dic_text!
        
        return errorTwcb == nil ? icvt.main(r1) : errorTwcb!
    }()
    fileprivate func step2a_mergeAllVersion() {
        var re: [DText] = []
        re.append(contentsOf: [
            DText("CBOL版本字典"),
            DText(isNewLine: true),
        ])
        re.append(contentsOf: _reDTextsCbol)
        re.append(contentsOf: [
            DText(isNewLine: true),
            DText(isNewLine: true),
            DText("浸宣版本字典"),
            DText(isNewLine: true),
        ])
        re.append(contentsOf: _reDTextsTwcb)
        re.append(contentsOf: [
            DText(isNewLine: true),
            DText(isNewLine: true),
            DText("CBOL Version Dictionary"),
            DText(isNewLine: true),
        ])
        re.append(contentsOf: _reDTextsCbolEn)
        self.resultContent = re
    }
    private func _getResultWhereActionTp()->[DText]{
        switch _dtext.snAction {
        case .cbol:
            return _reDTextsCbol
        case .cbole:
            return _reDTextsCbolEn
        case .twcb:
            return _reDTextsTwcb
        default:
            return [DText("錯誤的結果, snAction意外的值 \(_dtext.snAction!.rawValue)")]
        }
    }
}

