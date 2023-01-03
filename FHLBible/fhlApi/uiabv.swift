//
//  uiabv.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/16.
//

import Foundation
import UIKit
import CoreData

/// 用 auto load duiabv ， 不要用這個
/// 因為這個程式一開始就執行了一次這個
func fhlUiabv(_ param: String,_ fn: @escaping FhlJson<DApiUiabv>.FnCallback) {
    fhlCore(param, "uiabv", fn)
}

fileprivate protocol IAutoLoadDuiabvSQLite {
    /// 0, 非 gb 版, 1 gb 版, 只有 record 的資料是有存的
    func load()->(DApiUiabv?,DApiUiabv?)
    func update(_ re:DApiUiabv,_ reGb:DApiUiabv)
}

class AutoLoadDUiabv {
    static var s = AutoLoadDUiabv()
    func reloadAsync(){
        /// 嘗試從 cache 取得
        let sq = _isq.load()
        if sq.0 != nil && sq.1 != nil {
            self._reApi = sq.0
            self._reApiGb = sq.1
            print ("uiabv init from sqlite.")
        }
        
        /// 開始取得
        let group = DispatchGroup()
        group.enter()
        fhlUiabv("") { data in
            if data.isSuccess() { // 網路不通時，不可取代已有的資料
                self._reFromApi = data
            }
            group.leave()
        }
        group.enter()
        fhlUiabv("gb=1") { data in
            if data.isSuccess() {
                self._reFromApiGb = data
            }
            group.leave()
        }
        
        // 取得後更新
        group.notify(queue: .main){
            if self._isSuccessApi() {
                self._updateSqFromApiResult()
                self._replaceReUsingApiResult()
            }
        }
    }
    init () {
        reloadAsync()
    }
    private var _isq: IAutoLoadDuiabvSQLite = AutoLoadDuiabvSQLite()
    private var _reApi: DApiUiabv?
    private var _reApiGb: DApiUiabv?
    
    private var _reFromApi: DApiUiabv?
    private var _reFromApiGb: DApiUiabv?
    private func _isSuccessApi() -> Bool {
        let r1: [DApiUiabv?] = [_reFromApi, _reFromApiGb]
        if r1.ijnAny({$0 == nil}) { return false }
        
        let r2 = r1.map({$0!})
        if r2.ijnAny({$0.isSuccess()==false || $0.record!.count == 0}) { return false }
        return true
    }
    private func _updateSqFromApiResult(){
        _isq.update(self._reFromApi!, self._reFromApiGb!)
    }
    private func _replaceReUsingApiResult(){
        _reApi = _reFromApi
        _reApiGb = _reFromApiGb
    }
    
    func dateOfComment(isGb:Bool)-> Date? {
        if isGb{
            return _reApiGb?.getComment()
        }
        return _reApi?.getComment()
    }
    func dataOfParsing(isGb:Bool)->Date? {
        if isGb {
            return _reApiGb?.getParsing()
        }
        return _reApi?.getParsing()
    }
    var record: [DUiAbvRecord] { recordcore(gb: false) }
    var recordGb: [DUiAbvRecord] { recordcore(gb: true) }
    private func recordcore(gb:Bool)->[DUiAbvRecord]{
        let _reApi = gb ? self._reApiGb : self._reApi
        if (_reApi == nil || _reApi!.record == nil ){
            return []
        }
        return _reApi!.record!
    }
}

public class DUiAbvRecord : Decodable {
    init(_ na:String = ""){
        self.book = na
    }
    public var book : String
    public var cname : String?
    public var version : String?
    public var proc : Int?
    public var strong : Int?
    public var ntonly : Int?
    public var candownload : Int?
    public var otonly: Int?
    
    public func getVersion () -> Date? { return Date.ijnFromStr(version) }
}

class DApiUiabv : FhlJsonResult {
    private enum CodingKeys: String, CodingKey {
        case record
        case parsing
        case comment
    }
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        parsing = try? container.decode(String.self, forKey: .parsing)
        comment = try? container.decode(String.self, forKey: .comment)
        record = try? container.decode([OneRecord].self, forKey: .record)
        
        try super.init(from: decoder)
        
        // Decodable 在 class 繼承時，子類別不如預期的，會轉換成功 https://stackoverflow.com/questions/44553934/using-decodable-in-swift-4-with-inheritance
    }
    
    required public init(_ status: String = "") {
        record = []
        super.init(status)
    }
    public var parsing : String?
    public var comment : String?
    public var record : [OneRecord]?
    
    public func getParsing () -> Date? { return Date.ijnFromStr(parsing) }
    public func getComment () -> Date? { return Date.ijnFromStr(comment) }
    
    public typealias OneRecord = DUiAbvRecord
}

class AutoLoadDuiabvSQLite : IAutoLoadDuiabvSQLite {
    func load() -> (DApiUiabv?, DApiUiabv?) {
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
            print("load failure. \(error)")
        }
        return (nil,nil)
    }
    
    func update(_ re: DApiUiabv, _ reGb: DApiUiabv) {
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
                fatalError("update to abv sqlite failure, \(error)")
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
