//
//  ViewDisplayTable.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/27.
//

import Foundation
import UIKit

/// 當使用 viewDisplayTable 的 set 函式時，會先準備所有 datas，
/// 然而，datas 只會有 Address 的可能，這時候，也會同時產生 noData 是哪些 row
/// noData 是在 table 在 (需要指定 row 資料時, 判斷是否要使用 queryDataAsync 再補充資料 - 當然，這時 cell 的資料會先設空的 )
///
/// queryDataAsync 為了效率考量，雖然可以一次取一列，但一次取多列會更好。然而，為了避免取多列時，也已經有另一執行緒正在取
/// 所以就提供 datasQuerying 與 datasNoData 似參考用
///
/// 而 isAlreadyNoUse, 情境是 ... 當次執行緒取得後, 但其實 table 已經換一筆資料了, 也就是那些取到的資料若還拿去設定 cell, 則會錯誤
protocol IViewDisplayTable2DataQ {
    var isAlreadyNoUse: Bool { get }
    /// 要繪 table 的 data 已經有資料的 row
    var datas: [Int: ([DText],[[DText]]?)] { get }
    var onDatasGetter$: IjnEvent<IViewDisplayTable2DataQ,Any> { get }
    func queryDataAsync(_ rows:[Int])
    /// datas 中哪些 row 沒有 data
    var datasNoData: Set<Int> { get }
    /// datas 中哪些 row 正在抓取中
    var datasQuering: Set<Int> { get }
}

/// 因為有有一個1版本的，所以才叫2 (1已經不用了)
@IBDesignable
class ViewDisplayTable2 : ViewFromXibBase, UITableViewDataSource {
    typealias OneRow = (header:[DText],datas:[[DText]])
    /// header row = -1 , header col = -1, data is 0-based
    typealias OneEvent = (dtext: DText?,col:Int,row:Int)
    typealias OneLongEvent = (dtext: [DText]?,col:Int,row:Int)
    /// header row = -1, header col = -1, data is 0-based
    typealias OneSwitchChangedEvent = (isOn: Bool,col:Int,row:Int)
    /// 資料列，header 就是 col of -1，就是寫「羅11:1」那一欄
    /// 一格(Cell) 的資料，是一個 [DText]，一列資料是 [[DText]]
    var dataRows: [OneRow] = []
    /// 標頭列，header 就是 table 左上角那格， datas 就是放「新譯本，合和本那個。
    var dataHeader: OneRow = ([],[])
    /// 複選功能 [0] 是 row header [: , 0] 則是 column header
    var isOnOfSwitchs: [[Bool]] = []
    var _isSwitchVisible: Bool = false
    /// 目前，隨便一個預設值
    var _isSnVisible:Bool! = false
    /// 用此變數判定，是 mode 2 還是 原本的
    var _iViewDiplayTable2DataQ: IViewDisplayTable2DataQ?
    /// row = -1 就是 header row, col = -1 也是
    var onLongClickHeader$: IjnEvent<ViewDisplayCell, OneLongEvent> = IjnEvent()
    var onSwitchChanged$: IjnEvent<ViewDisplayCell, OneSwitchChangedEvent> = IjnEvent()
    var onClickHeader$: IjnEvent<ViewDisplayCell, OneEvent> = IjnEvent()
    var onClickDatas$: IjnEvent<ViewDisplayCell, OneEvent> = IjnEvent()
    /**
     長按事件，是為著複製經文用的。
     - addCallback 時， sender 會是當時送訊息的 cell，pData 會有 col, row ， col 或 row = -1 時，表示是 header (在閱讀時)
     */
    var onLongClickDatas$: IjnEvent<ViewDisplayCell, OneLongEvent> = IjnEvent()
    func setInitData(_ iDataGetter: IViewDisplayTable2DataQ,_ dataHeader: OneRow,_ isSnVisible: Bool,_ isFontNameOpenHanBibleTCs:[Bool], _ tpTextAlignment: [NSTextAlignment],isOnOffOfSwitchs: [[Bool]],isVisibleSwitch:Bool){
        self.dataRows = []
        self.dataHeader = dataHeader
        self._isSwitchVisible = isVisibleSwitch
        self.isOnOfSwitchs = isOnOffOfSwitchs
        self.widthRatio = ijnRange(0, dataHeader.datas.count).map({_ in 1.0})
        _isSnVisible = isSnVisible
        _isFontNameOpenHanBibleTCs = isFontNameOpenHanBibleTCs
        _tpTextAlignment = tpTextAlignment
        self._iViewDiplayTable2DataQ = iDataGetter
        _dictCell2Row.removeAll()
                
        viewTable.reloadData()
    }

    /**
     draw table 時，要設定的變數。
     - parameters:
        - dataHeader: 標題 row 的資料. 裡面包含了顯示經節位置的 col 與 經文 col。
        - dataRows: 經文 row 資料
        - isFontNameOpenHanBibleTCs: 外部會依 譯本 判定，是否 table 的 cell 字型要支援閩南語嗎。個數會與 ver 個數一樣，不是 col 個數。
        - tpTextAlignment: 依譯本判定，選擇合適的對齊方式，例如，希伯來文，是右側；中文，左右；英文，左對齊。個數與 ver 個數一樣多個，不是 col 個數。
        - isOnOfSwitchs: 選擇時，目前控制項是 on 還是 off，個數就是 row x col 個。
        - isVisibleSWitch: 當「閱讀」模式而非「選取」模式時，這個值就是讓 tablewview 裡的 rows 與 cells 都能 
     */
    func set(_ dataHeader: OneRow, _ dataRows: [OneRow],_ isSnVisible: Bool,_ isFontNameOpenHanBibleTCs:[Bool],_ tpTextAlignment:[NSTextAlignment],isOnOfSwitchs: [[Bool]],isVisibleSwitch:Bool){
        self._iViewDiplayTable2DataQ = nil
        self.dataHeader = dataHeader
        self.dataRows = dataRows
        self.isOnOfSwitchs = isOnOfSwitchs
        self._isSwitchVisible = isVisibleSwitch

        self._isFontNameOpenHanBibleTCs = isFontNameOpenHanBibleTCs
        _isSnVisible = isSnVisible
        _tpTextAlignment = tpTextAlignment
        
        self.widthRatio = ijnRange(0, dataHeader.datas.count).map({_ in 1.0})
        
        self.viewTable.reloadData()
    }
    
    /// 為了要給 cell 繪圖時，知道是台語版本，就可以使用字型。
    private var _isFontNameOpenHanBibleTCs: [Bool] = []
    /**
     傳入給 cells 的對齊。每個 rows 都會共用這組
     - 最令人困惑的，這個值通常是什麼？
     */
    private var _tpTextAlignment: [NSTextAlignment] = []
    
    override func initedFromXib() {
        // 避免一開啟當掉，我就不信有人會開 20 個譯本同時
        let tmp = IsOnOfSelectionsOfSwitch()
        tmp.resize(row: 40, col: 20)
        self.isOnOfSwitchs = tmp.isOns
        
        viewTable.register(MyCell.self, forCellReuseIdentifier: "cell")
        viewTable.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self._iViewDiplayTable2DataQ != nil {
            return _iViewDiplayTable2DataQ!.datas.count + 1 // + 1 就是版本那列
        }
        return dataRows.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MyCell
        
        if cell.viewWithTag(1) == nil {
            cell.initWhenTableNeed()
        }
        
        setRowViewWhenReuseCell(cell.viewRow,indexPath.row)
        return cell
    }
    private func reset_event_whenReuseCell(_ rowView: ViewDisplayRow,_ row: Int){
        // onClick, onLongClick, onSwitchChanged
        if row == 0 {
            rowView.onClickHeader$.clearCallback()
            rowView.onClickHeader$.addCallback {[weak self] sender, pData in
                self?.onClickHeader$.trigger(sender, (dtext: pData, col:-1, row: -1))
            }
            rowView.onClickData$.clearCallback()
            rowView.onClickData$.addCallback {[weak self] sender, pData in
                if pData == nil {
                    self?.onClickHeader$.trigger(sender, nil)
                } else {
                    self?.onClickHeader$.trigger(sender, (dtext: pData!.0, col: pData!.1, row: -1))
                }
            }
        } else {
            rowView.onClickHeader$.clearCallback()
            rowView.onClickHeader$.addCallback {[weak self] sender, pData in
                self?.onClickDatas$.trigger(sender, (dtext: pData, col:-1, row: row - 1))
            }
            rowView.onClickData$.clearCallback()
            rowView.onClickData$.addCallback {[weak self] sender, pData in
                if pData == nil {
                    self?.onClickDatas$.trigger(sender, nil)
                } else {
                    self?.onClickDatas$.trigger(sender, (dtext: pData!.0, col: pData!.1, row: row - 1))
                }
            }
        }
        
        // 2. LongClick
        if row == 0 {
            rowView.onLongClickHeader$.clearCallback()
            rowView.onLongClickHeader$.addCallback {[weak self] sender, pData in
                self?.onLongClickHeader$.trigger(sender, (dtext: pData, col:-1, row: -1))
            }
            rowView.onLongClickData$.clearCallback()
            rowView.onLongClickData$.addCallback {[weak self] sender, pData in
                if pData == nil {
                    self?.onLongClickHeader$.trigger(sender, nil)
                } else {
                    self?.onLongClickHeader$.trigger(sender, (dtext: pData!.0, col: pData!.1, row: -1))
                }
            }
        } else {
            rowView.onLongClickHeader$.clearCallback()
            rowView.onLongClickHeader$.addCallback {[weak self] sender, pData in
                let indexPath = IndexPath(row: row, section: 0)
                self?.viewTable.reloadRows(at: [indexPath], with: .automatic)
                self?.onLongClickDatas$.trigger(sender, (dtext: pData, col:-1, row: row - 1))
            }
            rowView.onLongClickData$.clearCallback()
            rowView.onLongClickData$.addCallback {[weak self] sender, pData in
                if pData == nil {
                    self?.onLongClickDatas$.trigger(sender, nil)
                } else {
                    self?.onLongClickDatas$.trigger(sender, (dtext: pData!.0, col: pData!.1, row: row - 1))
                }
            }
        }
        
        // 3. SwitchChanged
        rowView.onSwitchChanged$.clearCallback()
        rowView.onSwitchChanged$.addCallback {[weak self] sender, pData in
            guard let pData = pData, let self = self else {
                return
            }
            
            let isOn = pData.0
            let iCol = pData.1 // 與 click 不同， [0]是header, [1] 開始是譯本
            let dataSender: OneSwitchChangedEvent = (isOn: isOn, col: iCol, row: row)
            self.onSwitchChanged$.trigger( sender, dataSender)                    
        }
    }    
    private func setRowViewWhenReuseCell(_ rowView: ViewDisplayRow,_ row: Int){
        reset_event_whenReuseCell(rowView, row)
        
        if row == 0 {
            // header row
            let cntVer = dataHeader.datas.count
            let tpTextAlignments = ijnRange(0, cntVer).map({_ in NSTextAlignment.center})
            self._set_viewrow(viewRow: rowView, header: dataHeader.header, data: dataHeader.datas, rowOfTable: row, isHeader: true, tpTextAlignment: tpTextAlignments)
        } else {
            // data rows
            if _modeDraw == .ModeOrig {
                let dataRow = dataRows[row - 1]
                self._set_viewrow(viewRow: rowView, header: dataRow.header, data: dataRow.datas , rowOfTable: row, isHeader: false)
            } else {
                _drawUseMode2(row-1, rowView)
            }
        }
    }

    var _modeDraw: DrawMode { return self._iViewDiplayTable2DataQ == nil ? .ModeOrig : .ModeForSearch }
    func _drawUseMode2(_ rowOfData: Int,_ rowView: ViewDisplayRow){
        /// search result 會用到 mode2
        
        guard let iQ = _iViewDiplayTable2DataQ,let r1 = iQ.datas[rowOfData] else {
            return
        }
        
        // 忘了為何這麼作了。
        if r1.1 != nil {
            self._dictCell2Row.removeValue(forKey: rowView)
        } else {
            self._dictCell2Row[rowView] = rowOfData
        }
        
        let isHeader = false // UserMode2 一定不會有 header
        let dtextsData = r1.1 ?? ijnRange(0, dataHeader.datas.count).map({ _ in [DText("")]}) // n 格空白
        self._set_viewrow(viewRow: rowView, header: r1.0, data: dtextsData, rowOfTable: rowOfData+1, isHeader: isHeader)
        
        // 若是空的, 要嘗試取資料
        if r1.1 == nil {
            self._tryQueryDataThenUpdate(rowOfData)
        }
    }
    /// 許多參數，都是使用 self 資料，因此簡化。
    private func _set_viewrow(viewRow: ViewDisplayRow, header: [DText], data: [[DText]], rowOfTable: Int, isHeader: Bool,tpTextAlignment: [NSTextAlignment] = []){
        
        viewRow.set(header, data,
                    widthRatio,_isSnVisible,_isFontNameOpenHanBibleTCs,
                    tpTextAlignment.count == 0 ? _tpTextAlignment : tpTextAlignment, // 像 header 就會產生置中對齊
                    isHeaderRow: isHeader,
                    isOnOfSwitchs: self.isOnOfSwitchs[rowOfTable], //
                    isSwitchVisible: self._isSwitchVisible)
    }
    /// reload 時要清空
    /// reuse 時要設定, ( 只有資料是缺的, 才會在這個 dict 中 )
    /// 在 tryQueryData完成後，會被使用
    var _dictCell2Row: [ViewDisplayRow:Int] = [:]
    
    func _tryQueryDataThenUpdate(_ r: Int){
        let iQ = _iViewDiplayTable2DataQ!
        iQ.onDatasGetter$.addCallback {[weak self] sender, pData in
            guard let self = self else {
                return
            }
            
            let iQ2 = sender! // 存著取得資料結果，是個 字典，是 idxOfRow:資料
            if iQ2.isAlreadyNoUse == false {
                DispatchQueue.main.async {
                    let r1 = iQ2.datas
                    var r2 = self._dictCell2Row
                    let r3 = self.widthRatio
                    
                    var r4: [ViewDisplayRow] = []
                    for a2 in r2 {
                        let rowOfTable = a2.value
                        let r1a = r1[a2.value]!
                        if r1a.1 != nil { // 有資料了
                            
                            self._set_viewrow(viewRow: a2.key, header: r1a.0, data: r1a.1!, rowOfTable: a2.value, isHeader: false) // 這裡應該都是資料，而非 header
//                          a2.key.set(r1a.0, r1a.1!, r3, self._isSnVisible,self._isFontNameOpenHanBibleTCs,self._tpTextAlignment)

                            
                            r4.append(a2.key) // append 後, 等等要拿掉
                        } else { // 還是沒資料
                        }
                    }
                    
                    /// 高度要重算
                    if r4.count > 0 {
                        self.viewTable.beginUpdates()
                        self.viewTable.endUpdates()
                    }
                    r4.forEach({r2.removeValue(forKey: $0)})
                    self._dictCell2Row = r2
                }
            }
        }
        // 效率考量， +- 20 個一起取
        let cntLimit = iQ.datas.count
        let rows = ijnRange(r - 20, 40).filter({$0 >= 0 && $0 < cntLimit})
        iQ.queryDataAsync(rows)
    }
    private func getRowData(_ i: Int)-> [[DText]] {
        return self.dataRows[i].datas
    }
    private var widthRatio: [CGFloat] = [1.0]
    private func calcRatio(_ data:[DOneLine])->[CGFloat] {
        
        func fn2(_ i2:Int, _ a2: DText)->Int{
            if a2.children != nil {
                return a2.children!.reduce(0, fn2)
            } else {
                return a2.w != nil ? a2.w!.count : 0
            }
        }
        func fn1(_ a1: DOneLine) -> Int{
            var sum = 0
            for a2 in a1.children! {
                if a2.w != nil {
                    sum += a2.w!.count
                }
            }
            return sum
        }
        
        return data.map({ CGFloat(fn1($0)) })
    }
    
    override var nibName: String { "ViewDisplayTable2" }
    @IBOutlet weak var viewTable: UITableView!
    @IBOutlet weak var cellTable: UITableViewCell!
    
    class MyCell : UITableViewCell {
        var viewRow = ViewDisplayRow()
        func initWhenTableNeed(){
            viewRow.tag = 1
            contentView.addSubview(viewRow)
            viewRow.add4ConstrainsWithSuperView()
        }
    }
    enum DrawMode {
        case ModeOrig
        /// iViewDisplayTable2DataQ != nil
        case ModeForSearch
    }
}
