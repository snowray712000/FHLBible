//
//  EventsHelperOfTableOfRead.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/11.
//

import Foundation
import UIKit


protocol IEventsHelperOfTableOfRead {
    var pTable: ViewDisplayTable2 { get }
    var pVers: [String] { get }
    var pDatas: (title: ViewDisplayTable2.OneRow, data: [ViewDisplayTable2.OneRow])? { get }
}
/// 設定 onIndexCellChanged$，接著呼叫 starting
/// 通常是在 table 確定存在之後呼叫，建議 viewDidLoad
class EventsHelperOfTableOfRead {
    init(_ dataSource: IEventsHelperOfTableOfRead ) {
        self.pDataSource = dataSource
    }
    func starting(){
        let r1 = pDataSource.pTable
        r1.onClickHeader$.addCallback { sender, pData in
            if pData == nil { self.resetIRowIColPDText() }
            else {
                self.iCol = pData!.col
                self.iRow = pData!.row
                self.dtext = pData!.dtext
                self.onIndexCellChanged$.trigger(self, nil)
            }
        }
        r1.onClickDatas$.addCallback { sender, pData in
            if pData == nil { self.resetIRowIColPDText() }
            else {
                self.iCol = pData!.col
                self.iRow = pData!.row
                self.dtext = pData!.dtext
                self.onIndexCellChanged$.trigger(self, nil)
            }
        }
    }
    /// 供外部使用
    var onIndexCellChanged$: IjnEvent<EventsHelperOfTableOfRead,Any> = IjnEvent()
    
    /// 供外部使用
    var isRowOfHeader: Bool { iRow == -1 }
    /// 供外部使用
    var isColOfHeader: Bool { iCol == -1 }
    /// 供外部使用
    var pVer: String? {
        if iCol < 0 { return nil }
        let vers = pDataSource.pVers
        return vers[iCol]
    }
    /// 供外部使用
    /// 依 row 取得 那 row 的 addr 後，然後再 VerseRange 得到它的 addresses
    var pAddrs: VerseRange? {
        if iRow < 0 { return nil }
        let addrs = pDataSource.pDatas
        let r1 = addrs!.data[iRow]
        let r2 = r1.header.map({$0.w ?? ""}).joined(separator: "")
        return VerseRange(
        StringToVerseRange().main(r2, nil))
    }
    /// 供外部使用
    var pDText: DText? { dtext }
    
    /// -2  還沒初始化 -1 Header
    private var iCol:Int = -2
    /// -2  還沒初始化 -1 Header
    private var iRow:Int = -2
    /// 重置 事件原生 資料
    private func resetIRowIColPDText() { iCol = -2 ; iRow = -2 ; dtext = nil }
    /// 事件被 click 後的值
    private var dtext: DText?

    private var pDataSource: IEventsHelperOfTableOfRead!
    
}

