//
//  SQLNameOfFileAndTableRuler.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/26.
//

import Foundation

/// 為了產生 SQLBibles 存在的
/// 就是用 ver 、 目前 簡體/繁體  來決定 檔名
class SQLNameOfFileAndTableRuler : NSObject {
    /// sn_unv_gb
    var filenameOfSQL: String {
        get {
            // sn_unv.db unv.db unv_gb.db
            let r1 = isSnVisible() && isSnSupport() ? "sn_" : ""
            let r3 = isGb() && isDifferentBtwBig5AndGb() ?  "_gb" : ""
            return r1 + self.version + r3
        }
    }
    /// offline/sn_unv_gb.db
    var pathOfSQL: URL {
        get {
            let r1 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return r1.appendingPathComponent("offline/\(self.filenameOfSQL).db")
        }
    }
    /// sn_unv_gb2
    var nameOfTable: String {
        get {
            return self.filenameOfSQL + "2"
        }
    }
    private func isSnVisible()->Bool{
        return ManagerIsSnVisible.s.cur
    }
    private func isSnSupport()->Bool{
        return ["unv","kjv"].ijnAny({$0==self.version})
    }
    private func isGb()->Bool { return ManagerLangSet.s.curIsGb }
    private func isDifferentBtwBig5AndGb()->Bool {
        return ["kjv","asv"].ijnAll({$0==self.version}) == false
    }
    private var version: String!
    init(_ version:String){
        self.version = version
    }
}
