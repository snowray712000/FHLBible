//
//  VCIndex.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/28.
//

import Foundation
import UIKit
import ZIPFoundation
import zlib
import AVFoundation
import FHLCommon
import OSLog
class VCIndex : UIViewController {
    var logger = Logger(subsystem: "com.FHLBible", category: "VCIndex")

    @IBOutlet var viewDisplay: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        AutoLoadDUiabv.fnGFromSQLite = gAutoLoadDuiabvSQLite
        _ = AutoLoadDUiabv.s // lazy var
        
        // 發版本 (供 關鍵字搜尋，提醒 發版本要改什麼)
        labelDate.text = "2026.04.13a"
        labelVer.text = "4.11.1" //version
     
    }
    
    @IBAction func goRead(){
        // 若程式，開始的時候，沒有網路。
        logger.info("AutoLoadDUiabv record count: \(AutoLoadDUiabv.s.record.count)")
        if AutoLoadDUiabv.s.record.count == 0 {
            AutoLoadDUiabv.s.reloadAsync()
        }
        
        logger.info("AutoLoadDUiabv record count: \(AutoLoadDUiabv.s.record.count)")
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
    @IBAction func goData(){
        let vc = VCData()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func goHelp(){
        let vc = VCHelps()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var labelVer: UILabel!
}





