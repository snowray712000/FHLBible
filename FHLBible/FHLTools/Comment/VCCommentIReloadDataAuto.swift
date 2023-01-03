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

extension VCComment {
    class ReloadDataAutoUseOfflineOrScApi : IReloadData {
        
        override init(){
            super.init()
            if self.isExistOffline() {
                core = ReloadDataViaOfflineDatabase()
            } else {
                core = ReloadDataViaScApi()
            }
        }
        override var apiFinished$: IjnEventOnce<[DText],DReloadData> { get { return core!.apiFinished$ } }
        override func reloadAsync(_ addr: DAddress) {
            core!.reloadAsync(addr)
        }
        var core: IReloadData?
        private func isExistOffline() -> Bool {
            let na = ManagerLangSet.s.curIsGb ? "comm_gb.db" : "comm.db"
            let r1 = FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/\(na)")
            return FileManager.default.fileExists(atPath: r1.path)
        }
        
    }
}
