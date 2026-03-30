//
//  VCParsing.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/2.
//

import Foundation
import UIKit
import FHLCommon
import OSLog

/// 使用 set
class VCParsing : UIViewController {
    static var logger = Logger(subsystem: "com.FHLBible", category: "VCParsing")
    typealias FnCallback = (_ dataSet:[ViewParsing.OneSet],_ isHebrew: Bool) -> Void
    @IBOutlet weak var viewParsing: ViewParsing!
    @IBOutlet weak var btnTitle: UIButton!
    private var titleViewWidthConstraint: NSLayoutConstraint?
    var _vers: [String] = []
    lazy var eventKey: String = {
        return "VCParsing\(ObjectIdentifier(self).hashValue)"
    }()
    /// 這個較好用. set 後, 然後在 inited 時, 就會開始查詢資料
    /// vers 是加入 btnSnClicked 後，才需要的
    func set(_ addr: DAddress,_ vers:[String]){
        self._cur = addr
        self._vers = vers
    }
    /// 這個是以界面為概念的寫法
    func set(_ dataSets:[ViewParsing.OneSet]) {
        viewParsing._datas = dataSets
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitleView()
        
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
        
        viewParsing.evBtnSnClicked$.addCallback(self.eventKey){[weak self] sender, pData in
            if self == nil { return }
            
            // 判斷, 是 sn 嗎 (這段 code 參考 VCRead 中，當按下是 Sn 時的 callback
            if pData != nil && pData!.sn != nil {
                let addr = self?._cur
                if addr == nil { return }
                
                let r1 = SnDTextClickFlow(vc: self!, addr: addr!, vers: self!._vers)
                r1.mainAsync(pData!)
            }
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTitleViewLayout()
    }

    private func configureTitleView() {
        guard let titleView = navigationItem.titleView else { return }

        btnTitle.contentHorizontalAlignment = .center
        btnTitle.contentVerticalAlignment = .center
        btnTitle.titleLabel?.lineBreakMode = .byTruncatingTail
        btnTitle.titleLabel?.numberOfLines = 1
        btnTitle.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        if let existingConstraint = titleView.constraints.first(where: {
            $0.firstAttribute == .width && $0.secondItem == nil
        }) {
            titleViewWidthConstraint = existingConstraint
        } else {
            let constraint = titleView.widthAnchor.constraint(equalToConstant: 130)
            constraint.isActive = true
            titleViewWidthConstraint = constraint
        }
    }

    private func updateTitleViewLayout() {
        guard let titleView = navigationItem.titleView else { return }

        let navigationBarWidth = navigationController?.navigationBar.bounds.width ?? view.bounds.width
        let reservedWidth: CGFloat = 140
        let maxWidth = max(96, min(240, navigationBarWidth - reservedWidth))
        let fittingSize = btnTitle.systemLayoutSizeFitting(
            CGSize(width: UIView.layoutFittingCompressedSize.width, height: 44),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .required
        )
        let targetWidth = min(max(96, ceil(fittingSize.width)), maxWidth)

        titleViewWidthConstraint?.constant = targetWidth
        if titleView.bounds.width != targetWidth {
            titleView.bounds.size = CGSize(width: targetWidth, height: 44)
        }
    }
    deinit{
        viewParsing.evBtnSnClicked$.clearCallback(eventKey)
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
                self._cur = DAddress(book: pData!.idBook, chap: pData!.idChap, verse: 1)
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
                btnTitle.accessibilityLabel = r2
                updateTitleViewLayout()
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
        //let reloader: IReloadData = ReloadDataViaOfflineDatabase()
        let reloader: IReloadData = ReloadDataAutoUseOfflineOrScApi()
        
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
