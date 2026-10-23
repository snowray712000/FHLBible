//
//  ConvertorQp2VCParsingData.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/3.
//

import Foundation
import FHLCommon

/// Parsing 一個原文字的分析資料（SN、原文字、原型、分析、簡義、備註）
final class ParsingWord: Identifiable {
    let id = UUID()
    var sn: DText = DText()
    var word: DText = DText()
    var orig: DText = DText()
    var wform: [DText] = []
    var exp: [DText] = []
    var remark: [DText] = []
}
/// Parsing 一個分句：原文一行、中文一行，以及此分句內每個字的分析
struct ParsingClause: Identifiable {
    let id = UUID()
    var w: [DText]
    var cht: [DText]
    var words: [ParsingWord]
}

class ConvertorQp2VCParsingData {
    init(_ data: DData){
        self.data = data
    }
    var data: DData
    
    func main() -> (clauses: [ParsingClause], isHebrew: Bool){
        if data.isOldTestment() {
            mainOldTestment()
            return (dataResult,data.isOldTestment())
        } else {
            mainNewTestment()
            return (dataResult,data.isOldTestment())
        }
        // return ([],data.isOldTestment())
    }
    var dataResult: [ParsingClause] {
        get {
            assert(words?.count == exps?.count)
            assert(words?.count == dicts?.count)
            return ijnRange(0, words!.count).map({ i in
                return ParsingClause(w: words![i], cht: exps![i], words: dicts![i])
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
        
        var r6 = ijnRange(1, data.record.count - 1).map({ i -> ParsingWord in
            let a2 = data.record[i]
            
            let r5 = ParsingWord()
            r5.word = DText(a2.word!)
            r5.exp = [DText(a2.exp!)]
            let sn = trimLeadingZeros(a2.sn!)
            r5.sn = DText("G\(sn)", sn: sn, tp: "G", tp2: "WG")
            r5.wform = [DText(a2.pro),DText(a2.wform!)]
            r5.remark = [DText(a2.remark!)]
            r5.orig = DText(a2.orig!)
            
            return r5
        })
        
        // 2 4 3 3 3 表示 count 是 3 5 4 4 4 應該會等於 20 就是 r6 的數量
        // 但記得 希伯來文資料行與顯示順序是反的
        let r7 = r1.map({countSpaceAndDash(String($0))})
        
        var r8:[[ParsingWord]] = []
        for (i1,a1) in r7.enumerated() {
            var r8a: [ParsingWord] = []
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
        
        var r6 = ijnRange(1, data.record.count - 1).map({ i -> ParsingWord in
            let a2 = data.record[i]
            
            let r5 = ParsingWord()
            r5.word = DText(a2.word!)
            r5.exp = [DText(a2.exp!)]
            let sn = trimLeadingZeros(a2.sn!)
            r5.sn = DText("H\(sn)", sn: sn, tp: "H", tp2: "WH")
            r5.wform = [DText(a2.pro),DText(a2.wform!)]
            r5.remark = [DText(a2.remark!)]
            r5.orig = DText(a2.orig!)
            
            return r5
        })
        
        // 2 4 3 3 3 表示 count 是 3 5 4 4 4 應該會等於 20 就是 r6 的數量
        // 但記得 希伯來文資料行與顯示順序是反的
        let r7 = r1.map({countSpaceAndDash(String($0))})
        
        var r8:[[ParsingWord]] = []
        for (i1,a1) in r7.reversed().enumerated() {
            var r8a: [ParsingWord] = []
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
    /// 離線資料庫的 SN 帶前導 0（02532），去掉後才是字典、彙編查得到的編號 2532（全 0 時保留一個 0）
    private func trimLeadingZeros(_ sn: String) -> String {
        let r1 = sn.drop(while: { $0 == "0" })
        return r1.isEmpty ? String(sn.suffix(1)) : String(r1)
    }
    func countSpaceAndDash(_ str:String)->Int{
        let trimmed = str.trimmingCharacters(in: .whitespaces)
        let regSpace = try! NSRegularExpression(pattern: "[ -]+", options: [])
        return regSpace.numberOfMatches(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count))
    }
    var words: [[DText]]? = nil
    var exps: [[DText]]? = nil
    var dicts: [[ParsingWord]]? = nil
}
extension ConvertorQp2VCParsingData {
    public class DData {
        func isOldTestment()->Bool { return true }
        public var record: [DApiQpRecord]! { get { return [] } }
    }
    public class DDataViaQpApi : DData {
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
