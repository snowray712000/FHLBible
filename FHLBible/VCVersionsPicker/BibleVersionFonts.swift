//
//  BibleVersionFonts.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/26.
//

import Foundation

/// 有些版本的字型需要特別設定，否則有些字會顯示不出來
/// 例如，台語漢字、客語漢字
/**
 顯示經文的 table 裡面的 cell，有些譯本需要特別字型。例如，台語漢字、客語漢字
 */
class BibleVersionFonts : NSObject {
    /**
     依 vers 產生 對應的 bool[] 。
     */
    func mainIsOpenHanBibleTCs(_ vers:[String])->[Bool]{
        return vers.map({Self._OpenHanBibleTC.contains($0)})
    }
    /// OpenHanBibleTC open_han31.ttf
    fileprivate static var _OpenHanBibleTC: Set<String> = {
        return ["ttvh","thv12h","ttvhl2021"].ijnToSet() // 現代台語2013版漢字 客語漢字 現代台語2021版漢字
    }()
    
}
