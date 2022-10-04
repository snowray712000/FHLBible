//
//  VCSettings.swift
//  FHLBible
//
//  Created by littlesnow on 2021/12/1.
//

import Foundation
import UIKit

class VCSettings : VCOptionListViaTableViewControllerBase {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _onClickRow$.addCallback { sender, pData in
            self._doClickRow(pData!)
        }
    }
    
    override var _ovTitle1: [String] { self._datas.map({$0.0}) }
    override var _ovTitle2: [String]? { self._datas.map({$0.1}) }
    override var _ovColors: [UIColor]? { [.systemBlue, .label]}
    var _datas: [(String,String)] = [
        (NSLocalizedString("當機重置", comment: ""),NSLocalizedString("程式總是有Bug，當「閱讀」總是閃退，可能是某譯本、某章、某節、我沒處理好。按此功能，嘗試重置為「和合本，創世記1」", comment: "")),
        ("Bugs",NSLocalizedString("請至 support urls 回報{或觀看}目前已提出的問題與回饋。", comment: "")),
        
    ]
    
    
    func _doClickRow(_ row: Int) {
        
        var r1: [Int: ()->Void] = [:]
        r1[0] = self._doReset
        r1[1] = self._doListBugs
        
        let r2 = r1[row]
        if r2 != nil { r2!() }
        
    }
    func _doReset(){
        ManagerAddress.s.updateCur(VerseRange(DAddress(1,1,1).generateEntireThisChap()))
        ManagerBibleVersions.s.updateCur(["unv"])
        ManagerIsSnVisible.s.updateCur(true)
        
        let vc = UIAlertController(title: NSLocalizedString("訊息", comment: ""), message: NSLocalizedString("已重置，可再嘗試使用(1秒後繼續)", comment: ""), preferredStyle: .alert)
        self.navigationController?.present(vc, animated: true, completion: {
            sleep(1)
            vc.dismiss(animated: true, completion: nil)
        })
    }
    
    func _doListBugs(){
        let alert = UIAlertController(title: NSLocalizedString("打開到 support urls嗎？(https://bible.fhl.net/ios/FHLBibleSupport/index.html)", comment: ""), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in
            let urlString = "https://bible.fhl.net/ios/FHLBibleSupport/index.html"
            let url = URL(string: urlString)!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))
        self.present(alert, animated: true)
    }
}
