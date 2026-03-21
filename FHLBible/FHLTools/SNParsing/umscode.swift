//
//  umscode.swift
//  FHLBible
//
//  Created by littlesnow on 2024/10/6.
//

import Foundation

// 參考 code.php
func umscode(_ txt:String)->String{
  // 瘦母音, 胖母音, 右母音 專配 123，瘦子音配79，胖子音配111。 ... 其實 M 每 row 有 11 個。所以下面程式碼會 mod 11
    let M: [UInt8] = [34, 60, 62, 63, 58,  69, 73, 79, 85, 92,125,
        39, 44, 46, 47, 59, 101,105,111,117,124, 93,
        161,162,163,164,165,166,167,123,168,169,170] //母音全集

    let S: [UInt8] = [33,65,71,78,87,89,90,103,110,119,121,122,
        68,82,100,114,
        35,36,37,38,64,94,66,67,70,72,74,75,76,77,80,81,83,84,86,
            88,91,97,98,99,102,104,106,107,108,109,112,113,115,116,117,
            118,120,126,96] //子音全集
    let UA = ["ָ","ֶ","ְ","ֱ","ַ","ֵ","ִ","ֹ","ֻ","ֳ","ֲ"] // 全部 11 個母音

    let US = ["ן","וֹ","גּ","נּ","וּ","יּ","זּ","ג","נ","ו","י","ז",
    "דּ","רּ","ד","ר",
    "ץ","ך","ךְ","ךּ","ף","ךָ","בּ","צּ","שּׂ","הּ","טּ","כּ","לּ","מּ","פּ","קּ"
            ,"סּ","תּ","שּׁ","ש","ע","א","ב","צ","שׂ","ה","ט","כ","ל","מ",
            "פ","ק","ס","ת","","שׁ","ח","ם","׃"] // 全部 49 個子音

    let len = txt.count
    var ntxt = ""

    for pt in 0..<len {
        let now: Character = txt[txt.index(txt.startIndex, offsetBy: pt)]
        if let cx = now.asciiValue {
            if M.contains(cx) {
                let aid = M.firstIndex(of:cx)! // 找出母音在陣列中的位置，是 0-based 還是 1 based？ php 的 array_search 是 0-based
                let aid2 = aid % 11 //算出這是十一個母音中的第幾個
                ntxt = UA[aid2] + ntxt // 用母音的 unicode 來取代
            }
            else if S.contains(cx) {
                let sid = S.firstIndex(of:cx)!
                ntxt = US[sid] + ntxt
            }
            else {                
                ntxt = String(now) + ntxt
            }            
        } else {
            ntxt = String(now) + ntxt
        }
    }

    return ntxt
}
