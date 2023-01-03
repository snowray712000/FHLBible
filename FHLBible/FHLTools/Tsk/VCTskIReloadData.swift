//
//  VCComment.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation
import UIKit
import IJNSwift
import FMDB


extension VCTsk {
    /// 先開發 Comment 的，結果 Tsk 與它一樣
    typealias DReloadData = VCComment.DReloadData
    typealias DReloadData2 = VCComment.DReloadData2
    typealias IReloadData = VCComment.IReloadData
}

extension VCTsk {
    typealias DReloadDataViaScApi = VCComment.DReloadDataViaScApi
    
    class ReloadDataViaScApi : VCComment.ReloadDataViaScApi {
        override init(){
            super.init()
            self.tpSc = .tsk
        }
    }
}
