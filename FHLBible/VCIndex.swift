//
//  VCIndex.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/28.
//

import Foundation
import UIKit

class VCIndex : UIViewController {
    @IBOutlet var viewDisplay: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = AutoLoadDUiabv.s // lazy var
        
        labelDate.text = "2022.01.10a"
        labelVer.text = "1.4.1"
    }
    
    @IBAction func goRead(){
        // 若程式，開始的時候，沒有網路。
        print (AutoLoadDUiabv.s.record.count)
        if AutoLoadDUiabv.s.record.count == 0 {
            AutoLoadDUiabv.s.reloadAsync()
        }
        
        print (AutoLoadDUiabv.s.record.count)
        testThenDoAsync({ AutoLoadDUiabv.s.record.count != 0 }, {
            if AutoLoadDUiabv.s.record.count != 0 {
                let vc1 = self.gVCRead()
                let addr = VerseRange.globalManagerAddress.cur
                let vers = ManagerBibleVersions.s.cur
                vc1.setInitData(addr, vers)
                self.navigationController?.pushViewController(vc1, animated: true)
            }
        })
    }
    @IBAction func goSetting(){
        let vc = VCSettings()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var labelVer: UILabel!
}

