//
//  SSDivIdt.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation
import FHLCommon


func ssDtKjvRf (_ ds:[DText])->[DText]{
    return doSSDTextCore(ds, {SSKjvRF()})
}
func ssDtKjvFi (_ ds:[DText])->[DText]{
    return doSSDTextCore(ds, {SSKjvFi()})
}
func ssDtKjvCM (_ ds:[DText])->[DText]{
    return doSSDTextCore(ds, {SSKjvCM()})
}
func ssDtKjvFoFo(_ ds:[DText])->[DText]{
    return doSSDTextCore(ds, {SSKjvFoFo()})
}



/// <RF> <Rf>
fileprivate class SSKjvRF : SplitStringDTextBtwBase {
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.w == "<RF>"
    }
    override func ovGRegexp() -> NSRegularExpression {
        return try! NSRegularExpression(pattern: #"<RF>|<Rf>"#, options: [])
    }
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        let re = DText()
        re.children = dtexts
        re.tpContain = "kjvrf"
        return re
    }
}
fileprivate class SSKjvFi : SplitStringDTextBtwBase {
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.w == "<FI>"
    }
    override func ovGRegexp() -> NSRegularExpression {
        return try! NSRegularExpression(pattern: #"<FI>|<Fi>"#, options: [])
    }
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        let re = DText()
        re.children = dtexts
        re.tpContain = "kjvfi"
        return re
    }
}
fileprivate class SSKjvFoFo : SplitStringDTextBtwBase {
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.w == "<FO><FO>"
    }
    override func ovGRegexp() -> NSRegularExpression {
        return try! NSRegularExpression(pattern: #"<FO><FO>|<Fo><Fo>"#, options: [])
    }
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        let re = DText()
        re.children = dtexts
        re.tpContain = "kjvfo"
        return re
    }
}

fileprivate class SSKjvCM : SplitStringDTextCore {
    override var ovReg: NSRegularExpression { Self.reg }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneFromSrc: DText) -> DText {
        // 應該是一個段落，所以用 br 來作
        cloneFromSrc.w = nil
        cloneFromSrc.isBr = 1
        return cloneFromSrc
    }
    static var reg = try! NSRegularExpression(pattern: #"<CM>"#, options: [])
}
