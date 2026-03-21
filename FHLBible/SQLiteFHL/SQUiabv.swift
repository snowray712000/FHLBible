//
//  SQUiabv+CoreDataClass.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/29.
//
//

import Foundation
import CoreData
import FHLCommon
import OSLog
/// 無法重構至
public class AutoLoadDuiabvSQLite : IAutoLoadDuiabvSQLite {
    var logger = Logger(subsystem: "FHLBible", category: "AutoLoadDuiabvSQLite")

    public func load() -> (DApiUiabv?, DApiUiabv?) {
        let moc = _moc
        let r1 = SQUiabv.fetchRequest()
        do {
            // sqlite 資料，取到 _data 的 map 中
            let re = try moc.fetch(r1)
            for a1 in re {
                let o = One()
                o.cname = a1.cname
                o.cnameGb = a1.cnameGB
                o.version = a1.version
                _data[a1.book!] = o
            }
            
            // generate result
            let re1 = self._gRe(gb: false)
            let re2 = self._gRe(gb: true)
            return (re1,re2)
            
        }catch{
            self.logger.error("load failure. \(error.localizedDescription)")
        }
        return (nil,nil)
    }
    
    public func update(_ re: DApiUiabv, _ reGb: DApiUiabv) {
        if re.isSuccess() && reGb.isSuccess() {
            // 整理 gb 與 非 gb 版的 record 到 data
            self._setToData(re.record!, reGb.record!)
            
            // 更新到 sqlite 中
            let moc = _moc
            let r1 = SQUiabv.fetchRequest()
            do {
                let re = try moc.fetch(r1)
                for a1 in _data {
                    let r2 = re.ijnFirstOrDefault({$0.book == a1.key}) ?? SQUiabv(context: moc)
                    r2.book = a1.key
                    r2.cname = a1.value.cname
                    r2.cnameGB = a1.value.cnameGb
                }
                try moc.save()
            } catch {
                self.logger.error("update to abv sqlite failure, \(error.localizedDescription)")
                
            }
        }
    }
    private func _gRe(gb:Bool)-> DApiUiabv {
        let re = DApiUiabv("success")
        re.record = []
        
        for a1 in _data {
            let o = DUiAbvRecord(a1.key)
            o.cname = gb ? a1.value.cnameGb : a1.value.cname
            o.version = a1.value.version
            re.record?.append(o)
        }
        return re
    }
   
    
    private var _moc: NSManagedObjectContext { getMoc()}
    private func _setToData(_ record:[DUiAbvRecord],_ recordGb:[DUiAbvRecord]){
        for a1 in record {
            let r2 = _data[a1.book] ?? One()
            r2.cname = a1.cname
            r2.version = a1.version
            _data[a1.book] = r2
        }
        for a1 in recordGb {
            let r2 = _data[a1.book] ?? One()
            r2.cnameGb = a1.cname
            r2.version = a1.version
            _data[a1.book] = r2
        }
    }
    
    var _data: [String:One] = [:]
    class One {
        var cname: String?
        var cnameGb: String?
        var version: String?
    }
   
}

func gAutoLoadDuiabvSQLite()->AutoLoadDuiabvSQLite{
    return AutoLoadDuiabvSQLite()
}
