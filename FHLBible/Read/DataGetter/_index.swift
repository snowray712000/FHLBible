//
//  File.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/9/10.
//

import Foundation




/// 這個資料夾，是為了實作 IDataGetter
/// 主要 DataGetterUsingBibleReader 就是將 BibleReadDataGetter 轉換為 IDataGetter
/// 當然，BibleReadDataGetter 就是按 IDataGetter 設計的 (取得資料部分，事件部分由別處實作)
/// 若要看 Code ， 就是要先看 BibleReadDataGetterTests Unit Test 最下面的部分
///
/// BibleReadDataGetter 的設計，依照 IDataGetter
/// input 是 羅2:1-4，["和合本","新譯本"]
/// output 是 async callback 呼叫 vers: [DOneLine], datas: [[DOneLine]]
/// 主要工作，整合多個版本 (多執行緒抓取、同步等待完成，抓好後，多版本同節Merge，轉換結果)
/// 需求 interface，各別版本抓資料，交給 IBibleGetter (實作由 BibleGetterViaFhlApiQsb)
///
/// BibleGetterViaFhlApiQsb
/// input 是 "羅2:1-4"，"和合本"
/// output 是 async callback 呼叫 datas: [DOneLine]
/// 主要工作，預備參數給 QsbApi ，例如 將 "和合本" 轉為 unv
/// 需求 interface，純文字結果，轉換為定義的 DText 格式 。(實作由 BibleText2DText )
