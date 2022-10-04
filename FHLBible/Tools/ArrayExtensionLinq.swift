//
//  ArrayExtensionLinq.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/14.
//

import Foundation

/// Linq Range
/// - Parameters:
///   - start: start
///   - count: count
///   - delta: 當1的時候，核心是用 Range 產生。
/// - Returns: 陣列
public func ijnRange(_ start:Int,_ count:Int,_ delta:Int = 1)-> [Int] {
    if (delta==1){
        return Array(start..<(start+count))
    }
    var r1 = start
    var cnt = 0
    var re: [Int]=[]
    while ( cnt < count ){
        re.append(r1)
        r1 += delta
        cnt += 1
    }
    return re
}

// linq
extension Array {
    public func ijnAny(_ fn: (Element) -> Bool) -> Bool {
        for a1 in self {
            if ( fn(a1) ) { return true }
        }
        return false
    }
    public func ijnAll(_ fn: (Element) -> Bool) -> Bool {
        for a1 in self {
            if ( !fn(a1) ) { return false }
        }
        return true
    }
    public func ijnIndexOf<T : Equatable>(_ x:T) -> Int? {
        for i in 0..<self.count {
            if self[i] as! T == x {
                return i
            }
        }
        return nil
    }
    public func ijnFirstOrDefault<T : Equatable>(_ x:T) -> Element? {
        for a1 in self {
            if a1 as! T == x {
                return a1
            }
        }
        return nil
    }
    public func ijnFirstOrDefault(_ fn: (Element) -> Bool) -> Element? {
        for a1 in self {
            if fn(a1) {
                return a1
            }
        }
        return nil
    }
}
