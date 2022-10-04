//
//  testThenDo.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/9/4.
//

import Foundation

/// 會回到主執行緒，等待 0.3 s 一次，上限50次，會有 print 等待資訊
public func testThenDoAsync(_ fnTest: @escaping ()->Bool,_ fn: @escaping ()->Void,_ msg: String? = nil){
    var cnt = 0
    func fnLoop(){
        if ( fnTest() ){
            DispatchQueue.main.async {
                fn()
            }
        } else {
            cnt += 1
            if (msg == nil ) {                print ("wait testThenDo")}
            else{                 print ("wait " + msg!)}
            if ( cnt > 50){
                print("waiting count over 50.")
            }else {
                DispatchQueue.global().asyncAfter(deadline: .now()+0.3, execute: fnLoop )
            }
        }
    }
    
    fnLoop()
}
