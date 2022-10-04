//
//  VCVersionsCompareInOneVerse.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/26.
//

import Foundation
import UIKit

class VCVersionsCompareInOneVerse : UIViewController {
    func setInitData(_ addr:DAddress){
        _addr = addr
        _addrOnChanged$.trigger()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // title
        _addrOnChanged$.addCallback { sender, pData in
            self._drawTitle()
        }
        // 點擊，版本，可版本切換
        _v2.onClickHeader$.addCallback { sender, pData in
            if pData != nil {
                if pData!.col == -1 {
                    self._doSwitchVersions()
                }
            }
        }
        
        // 畫圖的資料 (抓資料,並 trigger)
        _addrOnChanged$.addCallback { sender, pData in
            self._queryData()
        }
        _versOnChanged$.addCallback { sender, pData in
            self._queryData()
        }
        
        // 畫圖
        _datasOnChanged$.addCallback { sender, pData in
            self._drawDatas()
        }
        
        // 點擊內容，可以觸發的
        _v2.onClickDatas$.addCallback { sender, pData in
            if pData != nil && pData!.dtext != nil {
                let dtext = pData!.dtext!
                if dtext.sn != nil {
                    SnDTextClickFlow(vc: self, addr: self._addr, vers: self._vers).mainAsync(dtext)
                } else if dtext.refDescription != nil {
                    RefDTextClickFlow(vc: self, addr: self._addr, vers: self._vers).mainAsync(dtext)
                } else if dtext.foot != nil {
                    
                    let ver = self._vers[ pData!.row ]
                    
                    let vc = FooterDTextClickFlow(vc: self, vers: ManagerBibleVersions.s.cur)
                    vc.mainAsync(dtext, ver, self._addr)
                }
            }
        }
        
        // 維護全域
        _versOnChanged$.addCallback { sender, pData in
            ManagerBibleVersionsForCompare.s.updateCur(self._vers)
        }
        
        _swipe.addSwipe(dir: .left)
        _swipe.addSwipe(dir: .right)
        _swipe.onSwipe$.addCallback { sender, pData in
            if pData?.direction == .right {
                self.goPrevVerse()
            } else if pData?.direction == .left {
                self.goNextVerse()
            }
        }
        
        _vers = ManagerBibleVersionsForCompare.s.cur
        _isSn = false
        
        // trigger first (setInitData 比較早被呼叫)
        _addrOnChanged$.trigger()
    }
    lazy var _swipe = SwipeHelp(view: self.view)
    fileprivate var _addr: DAddress!
    fileprivate var _addrOnChanged$: IjnEventAny = IjnEvent()
    fileprivate var _vers: [String]!
    fileprivate var _versOnChanged$: IjnEventAny = IjnEvent()
    fileprivate var _isSn: Bool = false
    @IBOutlet var viewTable: UIView!
    fileprivate var _v2: ViewDisplayTable2 { viewTable as! ViewDisplayTable2 }
    fileprivate var _datas: [[DText]] = []
    fileprivate var _datasOnChanged$: IjnEventAny = IjnEvent()
    fileprivate func _drawDatas(){
        if _vers.count != _datas.count { return } // 連續切換了2次版本，而且很快
        
        let dataHeader: ViewDisplayTable2.OneRow = {
            return ([DText("版本",isParenthesesHW: true)],[[DText("")]])
        }()
        let dataRows: [ViewDisplayTable2.OneRow] = {
            return ijnRange(0, self._datas.count).map({ i in
                let na = self._vers[i]
                let cna = BibleVersionConvertor().na2cna(na)
                
                let da = self._datas[i]
                return ([DText(cna)],[da])
            })
        }()
        
        _v2.set(dataHeader, dataRows, _isSn, BibleVersionFonts().mainIsOpenHanBibleTCs(_vers), getTpTextAlignmentsViaBibleVersions(_vers))
    }
    fileprivate func _drawTitle(){
        self.title = _addr.toString(ManagerLangSet.s.curTpBookNameLang)
    }
    fileprivate func _queryData(){
        let iDataQ: IVCReadDataQ = ReadDataQ()
        iDataQ.qDataForRead$.addCallback { sender, pData in
            
            let data = pData!.1
            let data1 = data.first // vers 多個版本.
            if data1 != nil {
                self._datas = data1!.datas
                self._datasOnChanged$.trigger()
            }
            
            //self._data = (title: pData!.0, data: pData!.1)
            //self._dataChanged$.trigger(nil, nil)
        }
        // 測試，林後，提後，繁簡英
        // 成功，都成功
        iDataQ.qDataForReadAsync(_addr!.toString(ManagerLangSet.s.curTpBookNameLang), _vers)
    }
    fileprivate func _doSwitchVersions(){
        let vc = self.gVCVersionsPicker()
        vc.setInitData(self._vers, isUpdateCurVersWhenOkay: false)
        vc.onClickOkay$.addCallback { sender, pData in
            if pData != nil {
                self._vers = pData!
                self._versOnChanged$.trigger()
            }
        }
        self.navigationController?.pushViewController(vc, animated: false)
    }
    @IBAction func goNextVerse(){
        _addr = _addr.goNextVerse()
        _addrOnChanged$.trigger()
    }
    @IBAction func goPrevVerse(){
        _addr = _addr.goPrevVerse()
        _addrOnChanged$.trigger()
    }
}
