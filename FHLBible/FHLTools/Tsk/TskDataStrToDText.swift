//
//  TskDataStrToDText.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation

class TskDataStrToDText {

    
    func main(_ str:String,_ addr:DAddress)->[DText] {
        self._addr = addr
        
        let rr1 = SplitByRegex().main(str: str, reg: Self.regNewLine)
        
        if rr1 == nil {
            return step1b(str)
        } else {
            var rr2: [DText] = []
            for a1 in rr1! {
                if a1.isMatch() {
                    rr2.append(DText(isNewLine: true))
                } else {
                    rr2.append(contentsOf: step1b(String(a1.w)))
                }
            }
            return rr2
        }
    }
    
    fileprivate func step1b(_ str: String) -> [DText] {
        let r1 = SplitByRegex().main(str: str, reg: Self.reg)
        
        if ( r1 == nil ){
            return [DText(str)]
        } else {
            return r1!.map { a1->DText in
                if a1.isMatch() {
                    return cvtOne(a1)
                } else {
                    return DText(String(a1.w))
                }
            }
        }
    }
    
    fileprivate func cvtOne(_ a2: SplitByRegexOneResult) -> DText {
        assert( a2.exec[1] != nil ) // 外面用 isSuccess () Filter 了
        let w = String(a2.exec[0]!)
        let rr1 = String(a2.exec[1]!)
        
        let r1 = rr1.firstIndex(of: ";")
        if r1 == nil {
            return step2(rr1, rr1, w)
        } else {
            let r2 = String(rr1[..<r1!])
            return step2(r2, rr1, w)
        }
        // 24,52;
        // 1:24,42;
        // Gen 1:24,42;
        
    }
    /// rr1, 是第1個 ; 之前的字串
    /// rr0, 是所有字, 但不包含前後的 # |
    /// w, 所有字
    fileprivate func step2(_ rr1: String, _ rr0: String,_ w:String) -> DText {
        let r2 = rr1.firstIndex(of: ":")
        if r2 == nil {
            // Case 5,24
            let re = "\(self._engs) \(self._chap):\(rr0)"
            return DText(w, refDescription: re, isInTitle: false)
        } else {
            let reg1 = try! NSRegularExpression(pattern: #"^\s*[a-zA-Z]+"#, options: [])
            let r3 = ijnMatchFirst(reg1, rr1)
            if r3 == nil {
                // Case 3:5,24
                let re = "\(self._engs)  \(rr0)"
                return DText(w, refDescription: re, isInTitle: false)
            } else {
                // Case Gen 3:5,24
                return DText(w, refDescription: rr0, isInTitle:  false)
            }
        }
    }
    /// 共用，不用一直每次都重建
    static var reg = try! NSRegularExpression(pattern: #"#([^\|]+)\|"#, options: [])
    static var regNewLine = try! NSRegularExpression(pattern: #"\s*\r?\n\s*"#, options: [])
    fileprivate var _addr: DAddress!
    fileprivate lazy var _engs: String = {
        return BibleBookNames.getBookName(_addr.book, .Matt)
    }()
    fileprivate lazy var _chap: Int = _addr.chap
}
