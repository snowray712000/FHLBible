//
//  FHLBibleTests.swift
//  FHLBibleTests
//
//  Created by snowray712000@gmail.com on 2021/4/12.
//

import XCTest
@testable import FHLBible

/// 為了 BibleReadDataGetter 開發 (實際用在 BibleGetterViaFhlApiQsb)
/// 仿 ts 流程
class QsbRecords2DOneLines : IQsbRecords2DOneLines {
    func cvt(_ records: [DApiQsbRecord], _ ver: String) -> [DOneLine] {
        abort()
    }
    
    
}

class QsbRecords2DOneLinesTests : XCTestCase {
    /// 併入上節. Ps8:6-8 https://bible.fhl.net/NUI/_rwd_dev/#/bible/Ps8:6-8
    /// 連續2個 a. 然後結束 ( 01b, 結束節不是落在a) Ps8:6-9
    func testMerge01a() throws {
        // /** 'a' 和合本 併入上節 Ps8:6-9 或 Ps8:6-9.60:1-2.92:1-4.Ps8:8 */
        let ra1 = DApiQsbRecord(engs: "Ps", chap: 8, sec: 6, bible_text: "你派他管理你手所造的，使萬物，就是一切的牛羊、田野的獸、空中的鳥、海裡的魚，凡經行海道的，都服在他的腳下。")
        let ra2 = DApiQsbRecord(engs: "Ps", chap: 8, sec: 7, bible_text: "a")
        let ra3 = DApiQsbRecord(engs: "Ps", chap: 8, sec: 8, bible_text: "a")
        
        let rb1 = DOneLine()
        rb1.addresses = "Ps8:6-8"
        rb1.children = [
            DText("你派他管理你手所造的，使萬物，就是一切的牛羊、田野的獸、空中的鳥、海裡的魚，凡經行海道的，都服在他的腳下。"),
        ]
        
        XCTAssertEqual([rb1], QsbRecords2DOneLines().cvt([ra1,ra2,ra3], "unv"))
    }
    /// 併入上節. Ps8:6-8 https://bible.fhl.net/NUI/_rwd_dev/#/bible/Ps8:6-9
    /// 連續2個 a. 再多1節, 使最後不落在 a 節
    func testMerge01b() throws {
        // /** 'a' 和合本 併入上節 Ps8:6-9 或 Ps8:6-9.60:1-2.92:1-4.Ps8:8 */
        let ra1 = DApiQsbRecord(engs: "Ps", chap: 8, sec: 6, bible_text: "你派他管理你手所造的，使萬物，就是一切的牛羊、田野的獸、空中的鳥、海裡的魚，凡經行海道的，都服在他的腳下。")
        let ra2 = DApiQsbRecord(engs: "Ps", chap: 8, sec: 7, bible_text: "a")
        let ra3 = DApiQsbRecord(engs: "Ps", chap: 8, sec: 8, bible_text: "a")
        let ra4 = DApiQsbRecord(engs: "Ps", chap: 8, sec: 9, bible_text: "耶和華─我們的主啊，你的名在全地何其美！")
        
        let rb1 = DOneLine()
        rb1.addresses = "Ps8:6-8"
        rb1.children = [
            DText("你派他管理你手所造的，使萬物，就是一切的牛羊、田野的獸、空中的鳥、海裡的魚，凡經行海道的，都服在他的腳下。"),
        ]
        let rb2 = DOneLine()
        rb2.addresses = "Ps8:9"
        rb2.children = [
            DText("耶和華─我們的主啊，你的名在全地何其美！"),
        ]
        
        XCTAssertEqual([rb1,rb2], QsbRecords2DOneLines().cvt([ra1,ra2,ra3,ra4], "unv"))
    }
    /// 併入上節. 但上節沒出來. 此時不自動再去補上節, 而是顯示為 〖併入上節〗
    /// Ps8:7-8 https://bible.fhl.net/NUI/_rwd_dev/#/bible/Ps8:7-8
    func testMerge02a() throws {
        let ra = [
            DApiQsbRecord(engs: "Ps", chap: 8, sec: 7, bible_text: "a"),
            DApiQsbRecord(engs: "Ps", chap: 8, sec: 8, bible_text: "a")
        ]
        
        let rb1 = DOneLine()
        rb1.addresses = "Ps8:7-8"
        rb1.children = [
            DText("〖併入上節〗")
        ]
        
        XCTAssertEqual([rb1], QsbRecords2DOneLines().cvt(ra, "unv"))
    }
    /// 併入上節. 含有 ( ) 的部分
    /// 3a 是 有 ( ) 合併 虛擬 case, 原本是 2-3 節合併, 讓它變為 1-3 節
    /// 3b 是 有 ( ) 但沒合併
    func testMerge03a() throws {
        // Ps8:6-9.60:1-2.92:1-4.Ps8:8 中的 92:1-4
        let reA : [DApiQsbRecord] = [
            DApiQsbRecord(engs: "Ps", chap: 92, sec: 1, bible_text: "（安息日的詩歌。）稱謝耶和華！歌頌你至高者的名！用十弦的樂器和瑟，用琴彈幽雅的聲音，早晨傳揚你的慈愛；每夜傳揚你的信實。這本為美事。"),
            DApiQsbRecord(engs: "Ps", chap: 92, sec: 2, bible_text: "a"),
            DApiQsbRecord(engs: "Ps", chap: 92, sec: 3, bible_text: "a"),
            DApiQsbRecord(engs: "Ps", chap: 92, sec: 4, bible_text: "因你─耶和華藉著你的作為叫我高興，我要因你手的工作歡呼。"),
        ]
        
        
        let reB : [DOneLine] = [
            DOneLine(addresses: "Ps92:1-3", children: [
                DText("（安息日的詩歌。）", isParenthesesFW: true),
                DText("稱謝耶和華！歌頌你至高者的名！用十弦的樂器和瑟，用琴彈幽雅的聲音，早晨傳揚你的慈愛；每夜傳揚你的信實。這本為美事。")
            ]),
               
            DOneLine(addresses: "Ps92:4", children: [
                DText("因你─耶和華藉著你的作為叫我高興，我要因你手的工作歡呼。")
            ])
    
        ]
        
        XCTAssertEqual(reB, QsbRecords2DOneLines().cvt(reA, "unv"))
    }

    func testMerge03b() throws {
        // Ps8:6-9.60:1-2.92:1-4.Ps8:8 中的 92:1-4
        let reA : [DApiQsbRecord] = [
            DApiQsbRecord(engs: "Ps", chap: 92, sec: 1, bible_text: "（安息日的詩歌。）稱謝耶和華！歌頌你至高者的名！"),
            DApiQsbRecord(engs: "Ps", chap: 92, sec: 2, bible_text: "用十弦的樂器和瑟，用琴彈幽雅的聲音，早晨傳揚你的慈愛；每夜傳揚你的信實。這本為美事。"),
            DApiQsbRecord(engs: "Ps", chap: 92, sec: 3, bible_text: "a"),
            DApiQsbRecord(engs: "Ps", chap: 92, sec: 4, bible_text: "因你─耶和華藉著你的作為叫我高興，我要因你手的工作歡呼。"),
        ]
        
        
        let reB : [DOneLine] = [
            DOneLine(addresses: "Ps92:1", children: [
                DText("（安息日的詩歌。）", isParenthesesFW: true),
                DText("稱謝耶和華！歌頌你至高者的名！")
            ]),
            DOneLine(addresses: "Ps92:2-3", children: [
                DText("用十弦的樂器和瑟，用琴彈幽雅的聲音，早晨傳揚你的慈愛；每夜傳揚你的信實。這本為美事。")
            ]),
            DOneLine(addresses: "Ps92:4", children: [
                DText("因你─耶和華藉著你的作為叫我高興，我要因你手的工作歡呼。")
            ])
    
        ]
        
        XCTAssertEqual(reB, QsbRecords2DOneLines().cvt(reA, "unv"))
    }
}
