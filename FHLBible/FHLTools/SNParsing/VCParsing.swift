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
            self.reloadDataAsync(self._cur!)
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
    }
    lazy var _swipeHelp = SwipeHelp(view: self.view)
    @IBAction func goNext(){
        if _next != nil {
            _cur = _next
            self.reloadDataAsync(_next!)
        }
    }
    @IBAction func goPrev(){
        if _prev != nil {
            _cur = _prev
            self.reloadDataAsync(_prev!)
        }
    }
    @IBAction func goSelectBook(){
        if _cur != nil {
            let vc2 = self.gVCBookChapPicker()
            vc2.initBeforePushVC(_cur!.book, _cur!.chap)
            vc2.onClick$.addCallback { sender, pData in
                self._cur = DAddress(book: pData!.idBook, chap: pData!.idChap, verse: 1, ver: nil)
                self.reloadDataAsync(self._cur!)
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


    
    private func updateNextPrevWhenGetQpResult(_ data: DReloadData){
        self._prev = data.addrPrev
        self._next = data.addrNext
    }
    func reloadDataAsync(_ addr: DAddress){
        //let reloader: IReloadData = ReloadDataViaScApi()
        let reloader: IReloadData = ReloadDataViaOfflineDatabase()
        
        reloader.apiFinished$.addCallback { sender, pData in
            if sender != nil {
                // error message. show sender message.
            } else {
                let re = ConvertorQp2VCParsingData(pData!.data!).main()
                DispatchQueue.main.async {
                    self.viewParsing._isRightToLeft = re.isHebrew
                    self.viewParsing._datas = re.0
                    
                    self.updateNextPrevWhenGetQpResult(pData!)
                }
            }
        }
        reloader.reloadAsync(addr)
    }
}
