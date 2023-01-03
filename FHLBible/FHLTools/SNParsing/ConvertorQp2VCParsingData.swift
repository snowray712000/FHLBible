//
//  ConvertorQp2VCParsingData.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/3.
//

import Foundation


class ConvertorQp2VCParsingData {
    init(_ data: DData){
        self.data = data
    }
    var data: DData
    
    func main() -> ([ViewParsing.OneSet],isHebrew:Bool){
        if data.isOldTestment() {
            mainOldTestment()
            return (dataResult,data.isOldTestment())
        } else {
            mainNewTestment()
            return (dataResult,data.isOldTestment())
        }
        // return ([],data.isOldTestment())
    }
    var dataResult: [ViewParsing.OneSet] {
        get {
            assert(words?.count == exps?.count)
            assert(words?.count == dicts?.count)
            return ijnRange(0, words!.count).map({ i in
                return (words![i],exps![i],dicts![i])
            })
        }
    }
    private func mainNewTestment(){
        let r1 = splitByNewLines(str: data.record[0].word!)
        let r2 = r1.map({[DText($0)]})
        let r2b = r2.map({ssDtGreekPlusPlusPlus($0, nil)})
        
        let r3 = splitByNewLines(str: data.record[0].exp!)
        let r4 = r3.map({[DText(String($0))]})
        assert(r1.count == r3.count)
        self.words = r2b
        self.exps = r4
        
        var r6 = ijnRange(1, data.record.count - 1).map({ i -> ViewParsingDict.OneData in
            let a2 = data.record[i]
            
            let r5 = ViewParsingDict.OneData()
            r5.word = DText(a2.word!)
            r5.exp = [DText(a2.exp!)]
            r5.sn = DText("G\(a2.sn!)", sn: "\(a2.sn!)", tp: "G", tp2: "WG")
            r5.wform = [DText(a2.pro),DText(a2.wform!)]
            r5.remark = [DText(a2.remark!)]
            r5.orig = DText(a2.orig!)
            
            return r5
        })
        
        // 2 4 3 3 3 表示 count 是 3 5 4 4 4 應該會等於 20 就是 r6 的數量
        // 但記得 希伯來文資料行與顯示順序是反的
        let r7 = r1.map({countSpaceAndDash(String($0))})
        
        var r8:[[ViewParsingDict.OneData]] = []
        for (i1,a1) in r7.enumerated() {
            var r8a: [ViewParsingDict.OneData] = []
            for _ in ijnRange(0, a1 + 1){
                if r6.count == 0 {
                    break
                }
                r8a.append(r6.removeFirst())
            }
            if i1 == r7.endIndex - 1 && r6.count != 0 {
                r8a.append(contentsOf: r6)
            }
            r8.append(r8a)
        }
        self.dicts = r8
    }
    private func mainOldTestment() {
        let r1 = splitByNewLines(str: data.record[0].word!)
        let r2 = r1.map({[DText($0)]})
        
        let r3 = splitByNewLines(str: data.record[0].exp!)
        let r4 = r3.map({[DText(String($0))]})
        
        assert(r1.count == r3.count)
        self.words = r2.reversed()
        self.exps = r4
        
        var r6 = ijnRange(1, data.record.count - 1).map({ i -> ViewParsingDict.OneData in
            let a2 = data.record[i]
            
            let r5 = ViewParsingDict.OneData()
            r5.word = DText(a2.word!)
            r5.exp = [DText(a2.exp!)]
            r5.sn = DText("H\(a2.sn!)", sn: "\(a2.sn!)", tp: "H", tp2: "WH")
            r5.wform = [DText(a2.pro),DText(a2.wform!)]
            r5.remark = [DText(a2.remark!)]
            r5.orig = DText(a2.orig!)
            
            return r5
        })
        
        // 2 4 3 3 3 表示 count 是 3 5 4 4 4 應該會等於 20 就是 r6 的數量
        // 但記得 希伯來文資料行與顯示順序是反的
        let r7 = r1.map({countSpaceAndDash(String($0))})
        
        var r8:[[ViewParsingDict.OneData]] = []
        for (i1,a1) in r7.reversed().enumerated() {
            var r8a: [ViewParsingDict.OneData] = []
            for _ in ijnRange(0, a1 + 1){
                if r6.count == 0 {
                    break
                }
                r8a.append(r6.removeFirst())
            }
            if i1 == r7.endIndex - 1 && r6.count != 0 {
                r8a.append(contentsOf: r6)
            }
            r8.append(r8a)
        }
        self.dicts = r8
        
    }
    func countSpaceAndDash(_ str:String)->Int{
        let regSpace = try! NSRegularExpression(pattern: "[ -]+", options: [])
        return regSpace.numberOfMatches(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count))
    }
    var words: [[DText]]? = nil
    var exps: [[DText]]? = nil
    var dicts: [[ViewParsingDict.OneData]]? = nil
}
extension ConvertorQp2VCParsingData {
    class DData {
        func isOldTestment()->Bool { return true }
        var record: [DApiQpRecord]! { get { return [] } }
    }
    class DDataViaQpApi : DData {
        override func isOldTestment() -> Bool {
            return _reApi.isOldTestment()
        }
        override var record: [DApiQpRecord]! {
            get {
                return _reApi.record
            }
        }
        init(_ resultApi: DApiQp){
            _reApi = resultApi
        }
        var _reApi: DApiQp!
    }
}
