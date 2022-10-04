//
//  File.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/9/10.
//

import Foundation

/// 為了 BibleReadDataGetter 開發 (實際用在 BibleGetterViaFhlApiQsb)
public protocol IQsbRecords2DOneLines {
    /// - Parameters:
    ///   - records: fhlQsb 結果
    ///   - ver: "unv" 等字串 (因為中文，有可能簡體繁體，所以直接用英文)
    func cvt(_ records: [DApiQsbRecord],_ ver: String) -> [DOneLine]
}

/// 同時需要 convertor protocol (IQsbRecords2DOneLines)
/// 到時候，會有一個「自動選擇來自 api、來自 local file database的」
class BibleGetterViaFhlApiQsb : IBibleGetter{
    private var cvtor: IQsbRecords2DOneLines = QsbRecords2DOneLines01()
    init(){
    }
    func queryAsync(_ ver: String, _ addr: String, _ fn: @escaping ([DOneLine]) -> Void) {        
        assert( AutoLoadDUiabv.s.record.count != 0 )
        let unv = BibleVersionConvertor().cna2na(ver)
        
        let r1 = "version=\(unv)&qstr=\(addr)&strong=1&\(ManagerLangSet.s.curQueryParamGb)"
        print (r1)
        fhlQsb(r1, { a2 in
            
            let re: [DOneLine] = false == a2.isSuccess() ? [] :
                self.cvtor.cvt(a2.record, unv)
            
            fn( re ) // 供 group.leave() 用
        })
        
    }
}

class BibleVersionConvertor: NSObject {
    /// 若找不到，就讓它等於原本的值
    func na2cna(_ na:String)->String {
        let r1 = pAbvResultData.ijnFirstOrDefault{($0.book == na)}
        return r1 == nil ? na : r1!.cname!
    }
    /// 若找不到，就讓它等於原本的值
    func cna2na(_ cna: String)->String {
        let r1 = pAbvResultData.ijnFirstOrDefault({$0.cname == cna})
        return r1 == nil ? cna : r1!.book
    }
    fileprivate var pAbvResultData: [DUiAbvRecord] {
        ManagerLangSet.s.curIsGb ? AutoLoadDUiabv.s.recordGb : 
        AutoLoadDUiabv.s.record }
}
