//
//  testThenDo.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/9/4.
//

import Foundation
import OSLog
/// 會回到主執行緒，等待 0.3 s 一次，上限50次，會有 print 等待資訊
public func testThenDoAsync(_ fnTest: @escaping ()->Bool,_ fn: @escaping ()->Void,_ msg: String? = nil){
    let logger = Logger(subsystem: "com.FHLBible", category: "testThenDoAsync")

    var cnt = 0
    func fnLoop(){
        if ( fnTest() ){
            DispatchQueue.main.async {
                fn()
            }
        } else {
            cnt += 1
            if (msg == nil ) {                logger.info("wait testThenDo")}
            else{                 logger.info("wait  \(msg!)")}
            if ( cnt > 50){
                logger.info("waiting count over 50.")
            }else {
                DispatchQueue.global().asyncAfter(deadline: .now()+0.3, execute: fnLoop )
            }
        }
    }
    
    fnLoop()
}
