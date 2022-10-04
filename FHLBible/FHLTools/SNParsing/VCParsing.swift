//
//  VCParsing.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/2.
//

import Foundation
import UIKit

/// 使用 set
class VCParsing : UIViewController {
    typealias FnCallback = (_ dataSet:[ViewParsing.OneSet],_ isHebrew: Bool) -> Void
    @IBOutlet var viewParsing: ViewParsing!
    @IBOutlet var btnTitle: UIButton!
    /// 這個較好用. set 後, 然後在 inited 時, 就會開始查詢資料
    func set(_ addr: DAddress){
        self._cur = addr
    }
    /// 這個是以界面為概念的寫法
    func set(_ dataSets:[ViewParsing.OneSet]) {
        viewParsing._datas = dataSets
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if _cur != nil {
            testCallAtInit(toParamString(_cur!))
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
        // _prev = DAddress(book: 1, chap: 2, verse: 1, ver: nil)
        // testCallAtInit("engs=Judg&chap=7&sec=1&gb=0")
        // testCallAtInit("engs=1%20Pet&chap=2&sec=1&gb=0")
    }
    lazy var _swipeHelp = SwipeHelp(view: self.view)
    @IBAction func goNext(){
        if _next != nil {
            _cur = _next
            testCallAtInit(toParamString(_next!))
        }
    }
    @IBAction func goPrev(){
        if _prev != nil {
            _cur = _prev
            testCallAtInit(toParamString(_prev!))
        }
    }
    @IBAction func goSelectBook(){
        if _cur != nil {
            let vc2 = self.gVCBookChapPicker()
            vc2.initBeforePushVC(_cur!.book, _cur!.chap)
            vc2.onClick$.addCallback { sender, pData in
                self._cur = DAddress(book: pData!.idBook, chap: pData!.idChap, verse: 1, ver: nil)
                self.testCallAtInit(self.toParamString(self._cur!))
            }
            self.navigationController?.pushViewController(vc2, animated: false)
        }
    }
    var _cur: DAddress? = nil {
        didSet{
            if _cur != nil {
                let r1 = BibleBookNames.getBookName(_cur!.book, .太)
                let r2 = "\(r1)\(_cur!.chap):\(_cur!.verse)"
                btnTitle!.setTitle(r2, for: .normal)
            }
        }
    }
    var _prev: DAddress? = nil
    var _next: DAddress? = nil

    private func toParamString(_ addr: DAddress)->String{
        let r1 = BibleBookNames.getBookName(addr.book, .Matt)
        return "engs=\(r1)&chap=\(addr.chap)&sec=\(addr.verse)&\(ManagerLangSet.s.curQueryParamGb)"
    }
    
    private func updateNextPrevWhenGetQpResult(_ data: DApiQp){
        func cvt(_ pn: DApiQp.PrevNext)->DAddress {
            let idBook = BibleBookNameToId().main1based(.Matt, pn.engs! )
            return DAddress(book: idBook, chap: pn.chap!, verse: pn.sec!, ver: nil)
        }
        
        if data.prev == nil {
            self._prev = nil
        } else {
            self._prev = cvt(data.prev!)
        }
        if data.next == nil {
            self._next = nil
        } else {
            self._next = cvt(data.next!)
        }
    }
    func testCallAtInit(_ param: String){
        fhlQp(param) { data in
            if data.isSuccess() {
                let re = ConvertorQp2VCParsingData(data).main()
                DispatchQueue.main.async {
                    self.viewParsing._isRightToLeft = re.isHebrew
                    self.viewParsing._datas = re.0
                    
                    self.updateNextPrevWhenGetQpResult(data)
                }
            }
        }
    }
}
