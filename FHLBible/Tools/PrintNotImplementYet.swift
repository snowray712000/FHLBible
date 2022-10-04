//
//  PrintNotImplementYet.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/19.
//

import Foundation
/**
 使用 abort () , 如果連 return 值都還沒有的時候
 */
public func ijnPrintNotImplentYet(_ file:String = #file, _ naFunc : String = #function, _ numberLine: Int = #line){
    let fileonly = URL(string: file)!.lastPathComponent
    print("not implement yet. \(fileonly) \(naFunc) \(numberLine)")
}
