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
    class ReloadDataViaOfflineDatabase : VCComment.ReloadDataViaOfflineDatabase {
        override init() {
            super.init()
            self.tagInDatabase = 4
        }
    }
}
