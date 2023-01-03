//
//  VCTsk.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation
import UIKit

class VCTsk : UIViewController {
    @IBOutlet var viewContent: UIView!
    /// addr 為何要傳呢？因為有的 19,27 變為 太2:19,27
    func setInitData(_ addr: DAddress){
        self._addr = addr
    }
    var _isVisibleSn: Bool = false // 串珠不須要 Sn
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 當點擊到裡面的 參考路徑時
        self.listenEventsWhenClickDtextInContent()
        
        // 資料更新，然再繪資料
        _addrChanged$.addCallback { sender, pData in
            self.title = "串珠 \(self._addrTitle)"
            self.v2.set([DText(NSLocalizedString("取得資料中...", comment: ""))], self._isVisibleSn)
            self._reloadData()
        }
        _dataChanged$.addCallback { sender, pData in
            self._draw()
        }
        
        _swipeHelp.addSwipe(dir: .left)
        _swipeHelp.addSwipe(dir: .right)
        _swipeHelp.onSwipe$.addCallback { sender, pData in
            if pData?.direction == .right {
                self.goPrev()
            } else if pData?.direction == .left {
                self.goNext()
            }
        }
        
        // 開始觸發
        _addrChanged$.trigger()
    }
    @IBAction func goNext(){
        if _addrNext != nil {
            _addr = _addrNext
            _addrChanged$.trigger()
        }
    }
    @IBAction func goPrev(){
        if _addrPrev != nil {
            _addr = _addrPrev
            _addrChanged$.trigger()
        }
    }

    fileprivate var _addr: DAddress!
    fileprivate var _addrChanged$: IjnEventAny = IjnEvent()
    /// data 取得後，會設定它 (供 next prev button 按)
    fileprivate var _addrNext: DAddress?
    fileprivate var _addrPrev: DAddress?
    
    fileprivate var _addrTitle: String { "\(BibleBookNames.getBookName(_addr.book, .太)) \(_addr.chap):\(_addr.verse)" }
    fileprivate var _data: [DText] = []
    fileprivate var _dataChanged$: IjnEventAny = IjnEvent()
    fileprivate func _draw(){ v2.set(self._data, self._isVisibleSn) }
    /// 用 addr 再重抓一次資料，並觸發 dataChanged$
    fileprivate func _reloadData(){
        let fnTriggerAtMainThread = {
            DispatchQueue.main.async {
                self._dataChanged$.trigger()
            }
        }
        
        let dataQ: IReloadData = ReloadDataAutoUseOfflineOrScApi()
        dataQ.apiFinished$.addCallback { sender, pData in
            if sender != nil {
                self._data = sender!
                fnTriggerAtMainThread()
            } else {
                let com_text = pData!.com_text!
                let dtexts = TskDataStrToDText().main(com_text, self._addr)
                self._data = dtexts
                self._addrNext = pData!.addrNext
                self._addrPrev = pData!.addrPrev
                fnTriggerAtMainThread()
            }
        }
        dataQ.reloadAsync(self._addr)
    }
    lazy var _swipeHelp = SwipeHelp(view:self.view)
    /// 方便用參數
    fileprivate lazy var v2: ViewDisplayCell = { viewContent as! ViewDisplayCell}()
    fileprivate func listenEventsWhenClickDtextInContent(){
        v2.onClicked$.addCallback { sender, pData in
            // print (pData?.w)
            if pData != nil {
                if pData!.refDescription != nil {
                    self.pushVCReadWhenClickContentRef(pData!)
                }
            }
        }
    }
    /// 回應事件，點擊到 reference 時。
    /// 串珠功能，最常用到的就是點擊到 reference。
    fileprivate func pushVCReadWhenClickContentRef(_ dtext: DText){
        assert( dtext.refDescription != nil )
        
        let vc1 = self.gVCRead()
        let r1a = dtext.refDescription!
        let r1b = VerseRange( StringToVerseRange().main(r1a) )
        let r2 = ManagerBibleVersions.s.cur
        vc1.setInitData(r1b, r2)
        self.navigationController?.pushViewController(vc1, animated: false)
    }
}

