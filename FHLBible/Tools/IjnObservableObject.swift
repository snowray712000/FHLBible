//
//  IJNObservableObject.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/15.
//

import Foundation

public class IjnObservableObject<T> {
    public init(_ initialValue: T?){self.value = initialValue}
    public typealias FnCallback = (_ new: T?, _ old: T?) -> Void
    internal var fnCallbacks: [FnCallback] = []
    public func addValueDidSetCallback(_ fn: @escaping FnCallback ){
        fnCallbacks.append(fn)
        // 加上 @escaping。因為會出現 Converting non-escaping parameter 'fn' to generic parameter 'Element' may allow it to escape
    }
    public func setValueDidSetCallback(_ fn: @escaping FnCallback){
        cleanValueDidSetCallbacks()
        fnCallbacks.append(fn)
    }
    public func cleanValueDidSetCallbacks(){
        fnCallbacks.removeAll()
    }
    public var value : T? = nil {
        didSet{
            for a1 in fnCallbacks {
                a1(value,oldValue) // oldValue 是關鍵字
            }
        }
    }
}
