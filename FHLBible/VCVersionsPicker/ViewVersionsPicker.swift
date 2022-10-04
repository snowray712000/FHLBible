//
//  VCVersionsPicker.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/4.
//

import UIKit

/// 使用 setInitData 初始化
/// 使用 datasSelection, datasRecently, datasSet 取得結果
class ViewVersionsPicker : ViewFromXibBase, UICollectionViewDataSource {

    
    override func initedFromXib() {
        initCollectionViews()
        initSub1Items()
        btnsSub2.forEach({$0.addAction(UIAction(handler: clickSub2), for: .primaryActionTriggered)})
        
        
        // 與下面的 buttons 相關的處理
        self.onChangedSub1$.addCallback { sender, pData in
            // 中文、英文 ... 按鈕按下時
            self.updateItemsVisibleNowFromSub1Sub2OnOff()
            self.drawVersionItems(nil, nil)
        }
        self.onChangedSub2$.addCallback { sender, pData in
            // 中文次分類按下時
            self.updateItemsVisibleNowFromSub1Sub2OnOff()
            self.drawVersionItems(nil, nil)
        }
        self.onChangedOnOff$.addCallback { sender, pData in
            self.updateItemsVisibleNowFromSub1Sub2OnOff()
            self.drawVersionItems(nil, nil)
        }
        self.onChangedSelections$.addCallback { sender, pData in
            self.updateItemsVisibleNowFromSub1Sub2OnOff()
            self.drawVersionItems(nil, nil)
        }
        
        // 與中間次分類，(顯示與否相關)
        self.onChangedSub1$.addCallback { sender, pData in
            let isOn = self.isOnOff
            self.scrollsSub2.forEach({$0.isHidden=self.sub1 != .ch || isOn==false})
            self.scrollsSub2.first!.isHidden = self.sub1 != .ch
        }
        self.onChangedOnOff$.addCallback { sender, pData in
            self.pScrollsSub2NonIncludeSwitch.forEach({$0.isHidden = !self.isOnOff})
        }
        
        // 畫 selection 與 recently 的 button
        self.onChangedSelections$.addCallback { sender, pData in
            self.drawSelections()
        }
        self.onChangedRecently$.addCallback { sender, pData in
            self.drawRecently()
        }
        // 畫 sets
        self.onChangedSelections$.addCallback { sender, pData in
            self.drawSets()
        }
        self.onChangedSets$.addCallback { sender, pData in
            self.drawSets()
        }
        
        // 初始動作
        
        drawSelections()
        drawRecently()
        drawSets()
    }
    
    func setInitData(_ naSelections:[String], _ naRecently:[String],_ naSets:[[String]],_ isOnSub:Bool,_ optSub1: BibleVersionConstants.TpGroup){
        self.datasSelection = naSelections
        self.datasRecently = naRecently
        self.datasSet = naSets
        
        self.btnOnOff.isOn = isOnSub // initedFromXib 比較早被呼叫
        self._drawSub1ButtonForInitSet(optSub1) // init once
        
        self.onChangedSelections$.trigger()
        self.onChangedRecently$.trigger()
        self.onChangedSets$.trigger()
        
        self.onChangedOnOff$.trigger(nil, nil)
        self.onChangedSub1$.trigger()
    }
    var onChangedSub1$: IjnEvent<ButtonSub1, Any> = IjnEvent()
    /// 從 controls 哪個被 isSelected 判斷
    var sub1: TpSub1ChEnHGMiHaOt {
        get {
            let r1 = ijnRange(1, stackSub1.subviews.count - 1).map({stackSub1.subviews[$0] as! ButtonSub1})
            let r2 = r1.ijnFirstOrDefault({$0.isSelected})
            if r2 != nil {
                return r2!.info!.na
            }
            return .ch // default value
        }
    }
    var onChangedSub2$: IjnEvent<ButtonSub2, Any> = IjnEvent()
    /// 從 constrols 取得, 目前有的 cds [] conditions
    var sub2: [TpSub2] {
        get {
            return btnsSub2.filter({$0.isSelected}).map({$0.info!})
        }
    }
    var onChangedOnOff$: IjnEvent<UISwitch, Any> = IjnEvent()
    var isOnOff: Bool {
        get { return self.btnOnOff.isOn }
    }
    var itemsVisibleNow: [OneVersionInfo] = []
    
    /// 這個只是 update 變數，不該從裡面去 trigger 什麼
    func updateItemsVisibleNowFromSub1Sub2OnOff(){
        let sub1 = sub1
        var pthisTp: [OneVersionInfo]? { pdatas.ijnFirstOrDefault({$0.na == sub1})?.vers }
        
        let thisTp = pthisTp
        if thisTp == nil {
            itemsVisibleNow = [] // error, set empty
            return
        }
        
        if sub1 != .ch || isOnOff == false {
            itemsVisibleNow = thisTp! // okay
            return
        } else {
            // sub2
            let sub2 = sub2
            itemsVisibleNow = thisTp!.filter({ a1 in
                if a1.cds == nil {
                    return true // a1 不需條件，那麼，一定成立
                }
                return a1.cds!.ijnAll({sub2.contains($0)}) // a1.cds 所需條件，若每個都存在目前 actived 的裡面，那麼，成立，顯示它
            }) // okay
            return
        }
    }
    var onChangedSelections$: IjnEvent<ButtonVersion, Any> = IjnEvent()
    var onChangedRecently$: IjnEvent<ButtonVersion, Any> = IjnEvent()
    var onChangedSets$: IjnEvent<ButtonVersion, Any> = IjnEvent()
    /// "uvn" "cnv" 之類的
    var datasSelection: [String] = []
    var datasRecently: [String] = []
    var datasSet:[[String]] = []
    /// (畫全部時) depend on viewCollectionItems
    /// (各別時 reuse) depend on viewCollectionItems and datasSelection
    /// nil 就是畫全部, 有傳入時, 就是 Reuse 時候用
    /// reuse, 會設定它的 title, color, info
    func drawVersionItems(_ btn: ButtonVersion? = nil,_ row: Int? = nil){
        if btn == nil || row == nil{
            // 方向改變
            let r2 = (self.viewCollectionItems.collectionViewLayout as! UICollectionViewFlowLayout)
            if self.itemsVisibleNow.count < 10 {
                r2.scrollDirection = .vertical
                self.btnDirectionImage.isHidden = true
            } else {
                r2.scrollDirection = .horizontal
                self.btnDirectionImage.isHidden = false
            }
            
            // 呼叫此之前，已經更新 itemsVisibleNow, 這裡不負責呼叫，而是取得那變數來使用
            self.viewCollectionItems.reloadData() // 搜尋關鍵字 collectionView ，可找到對應的 method
            // 上色 (reload 過程就會上色了)
            
        } else {
            let r1 = itemsVisibleNow[row!]
            btn!.info = r1
            btn!.setTitle(r1.cna, for: .normal)
            btn!.isSelected2 =  datasSelection.contains(r1.na)
        }
    }
    /// 在 draw Selections 或 Recently 的 buttons 時，那時候只有參數 na
    /// 要用 na 給完整的 info, 就要從 pdata 中去找囉
    private func findInfoWhereNa(_ na:String) -> OneVersionInfo? {
        let data = pdatas
        for a1 in data{
            for a2 in a1.vers! {
                if a2.na == na {
                    return a2
                }
            }
        }
        return nil
    }
    /// depend on datasSelection
    func drawSelections(){
        // 拿掉目前的
        let rs = stackSelection!
        let r1 = ijnRange(1, rs.subviews.count-1).map({rs.subviews[$0] as! ButtonVersion})
        r1.forEach({$0.removeFromSuperview()})
        
        // 新增新的進去
        datasSelection.map({ a1 -> ButtonVersion in
            let btn = ButtonVersion()
            let info = findInfoWhereNa(a1)!
            btn.info = info
            btn.setTitle(info.cna, for: .normal)
            btn.addAction(UIAction(handler: onClickVersionItem), for: .primaryActionTriggered) // 因為按上面按下面，流程一樣，所以直接用現成的
            return btn
        }).forEach({rs.addArrangedSubview($0)})
    }
    func drawRecently(){
        // 拿掉目前的
        let rs = stackRecently!
        let r1 = ijnRange(1, rs.subviews.count-1).map({rs.subviews[$0] as! ButtonVersion})
        r1.forEach({$0.removeFromSuperview()})
        
        // 新增新的進去
        datasRecently.map({ a1 -> ButtonVersion in
            let btn = ButtonVersion()
            let info = findInfoWhereNa(a1)!
            btn.info = info
            btn.setTitle(info.cna, for: .normal)
            btn.addAction(UIAction(handler: onClickVersionItemInRecently), for: .primaryActionTriggered) // 因為按上面按下面，流程一樣，所以直接用現成的
            return btn
        }).forEach({rs.addArrangedSubview($0)})
    }
    /// 還沒啟用
    func drawSets(){
        if datasSet.count == 0 {
            scrollSet.isHidden = true
            return
        }
        scrollSet.isHidden = false
        
        // 拿掉目前的
        let rs = stackSets!
        let r1 = ijnRange(1, rs.subviews.count-1).map({rs.subviews[$0] as! ButtonSet})
        r1.forEach({$0.removeFromSuperview()})
        
        // 新增新的進去
        datasSet.map({ a1 -> ButtonSet in
            let btn = ButtonSet()
            let infos = a1.map({findInfoWhereNa($0)}).filter({$0 != nil}).map({$0!})
            
            btn.info = infos
            btn.setTitle(btn.title, for: .normal)
            btn.addAction(UIAction(handler: onClickVersionItemInSets), for: .primaryActionTriggered) // 因為按上面按下面，流程一樣，所以直接用現成的
            
            // 只要 selections 中, 都包含了, 就變為 isSelect
            btn.isSelected2 = a1.ijnAll({datasSelection.contains($0)})
            return btn
        }).forEach({rs.addArrangedSubview($0)})
    }
    /// 只會在初始化時被呼叫一次
    /// 中文、英文 … 這些按扭
    func initSub1Items(){
        pdatas.forEach({ a1 in
            let btn = ButtonSub1()
            btn.info = a1
            btn.setTitle(a1.cna, for: .normal)
            btn.addAction(UIAction(handler: clickSub1), for: .primaryActionTriggered)
            self.stackSub1.addArrangedSubview(btn)
        })
    }
    /// 方便用
    var pButtonsSub1: [ButtonSub1] {
        get {
            return ijnRange(1, self.stackSub1.subviews.count - 1)
                .map({self.stackSub1.subviews[$0] as! ButtonSub1})
        }
    }
    /// 全域變數，要記住最後的選項用的
    var optSub1:  BibleVersionConstants.TpGroup {
        let r1 = pButtonsSub1.first(where: {$0.isSelected2})
        if r1 != nil { return r1!.info!.na }
        return pButtonsSub1.first!.info!.na
    }
    func _drawSub1ButtonForInitSet(_ na:BibleVersionConstants.TpGroup){
        let r1 = pButtonsSub1.first(where: {$0.info?.na == na}) ?? pButtonsSub1.first!
        r1.sendActions(for: .primaryActionTriggered)
    }
    
    /// 重新上色, depend on sub1
    /// 留著錯誤，作為提醒
    func drawSub1Items(){
        pButtonsSub1.forEach({ a1 in
                a1.isSelected2 = self.sub1 == a1.info!.na
            })
        abort() // 而現在這個函式又 反過來, 設計不良, 這個函式不該存在        
    }
    
    /// 雖然加 IBAction , 但實際是用程式 addAction 的
    @IBAction func clickSub1(_ action:UIAction){
        let btn = action.sender as! ButtonSub1
        pButtonsSub1.forEach({$0.isSelected2 = false})
        btn.isSelected2 = true
        self.onChangedSub1$.trigger(btn, nil)
    }
    /// 雖然加 IBAction , 但實際是用程式 addAction 的, 而且不知道, 為何不能從 IB 拉
    @IBAction func clickSub2(_ action:UIAction){
        let btn = action.sender as! ButtonSub2
        btn.isSelected2 = !btn.isSelected2
        self.onChangedSub2$.trigger(btn, nil)
    }
    /// 雖然加 IBAction , 但實際是用程式 addAction 的
    @IBAction func onClickVersionItem(action: UIAction){
        let btn = action.sender as! ButtonVersion
        let na = btn.info!.na
        
        var isChangeRecently = false
        
        let r1 = self.datasSelection.ijnIndexOf(na)
        if r1 == nil {
            self.datasSelection.append(na)
            
            let r2 = self.datasRecently.ijnIndexOf(na)
            if r2 != nil {
                self.datasRecently.remove(at: r2!)
                isChangeRecently = true
            }
        } else {
            self.datasSelection.remove(at: r1!)
            
            isChangeRecently = true
            self.datasRecently.insert(na, at:0)
//            self.datasRecently.append(na)
        }
        
        self.onChangedSelections$.trigger(btn, nil)
        if isChangeRecently {
            self.onChangedRecently$.trigger(btn, nil)
        }
    }
    /// 雖然加 IBAction , 但實際是用程式 addAction 的
    @IBAction func onClickVersionItemInRecently(action: UIAction){
        let btn = action.sender as! ButtonVersion
        let na = btn.info!.na
        
        self.datasSelection.append(na)
        let r1 = datasRecently.ijnIndexOf(na)!
        self.datasRecently.remove(at: r1)
        
        self.onChangedSelections$.trigger(btn, nil)
        self.onChangedRecently$.trigger(btn, nil)
    }
    /// 雖然加 IBAction , 但實際是用程式 addAction 的
    @IBAction func onClickVersionItemInSets(action: UIAction){
        let btn = action.sender as! ButtonSet
        
        // 拿掉原本 selections 中的
        for a1 in datasSelection {
            if datasRecently.contains(a1) == false {
                datasRecently.append(a1)
            }
        }
        datasSelection.removeAll()
        
        // 將 sets 中的版本新增進去
        let nas = btn.info!.map({$0.na})
        for a1 in nas {
            let i1 = datasRecently.ijnIndexOf(a1)
            if i1 != nil {
                datasRecently.remove(at: i1!)
            }
            datasSelection.append(a1)
        }
        
        onChangedSelections$.trigger(nil, nil)
        onChangedRecently$.trigger(nil, nil)
    }
    @IBAction func clickClearSets(){
        
    }
    @IBAction func clickClearSelections(){
        var isChangedRecently = false
        for a1 in datasSelection {
            if datasRecently.contains(a1) == false {
                datasRecently.append(a1)
                isChangedRecently = true
            }
        }
        datasSelection.removeAll()
        
        self.onChangedSelections$.trigger(nil, nil)
        if isChangedRecently {
            self.onChangedRecently$.trigger(nil, nil)
        }
    }
    @IBAction func clickClearRecently(){
        if datasRecently.count != 0 {
            datasRecently.removeAll()
            self.onChangedRecently$.trigger(nil, nil)
        }
    }
    @IBAction func clickSwitchOnOff(_ sender: UISwitch){
        onChangedOnOff$.trigger(sender, nil)
    }
    
    override var nibName: String {"ViewVersionsPicker"}
    
    @IBOutlet var stackSelection: UIStackView!
    @IBOutlet var stackRecently: UIStackView!
    @IBOutlet var stackSets: UIStackView!
    @IBOutlet var stackSub1: UIStackView!
    var pScrollsSub2NonIncludeSwitch: [UIScrollView] { ijnRange(1, 3).map({scrollsSub2[$0]})}
    /// 包含 開關 還有次分類的 那些 row ， 第1個是 開關
    @IBOutlet var scrollsSub2: [UIScrollView]!
    /// 使用 btnsSub
    /// 這個比 stacksSub 好用, 但 array outlet 必須用 內建的 class , 所以不能直接用 ButtonSub2
    @IBOutlet var _btnsSub: [UIButton]!
    private var btnsSub2: [ButtonSub2] { _btnsSub.map({$0 as! ButtonSub2}) }
    @IBOutlet var viewCollectionItems: UICollectionView!
    @IBOutlet var btnSelection: UIButton!
    @IBOutlet var btnRecently: UIButton!
    @IBOutlet var btnSets: UIButton!
    @IBOutlet var btnDirectionImage: UIButton!
    @IBOutlet var btnOnOff: UISwitch!
    @IBOutlet var scrollSet: UIScrollView!
    
    /// 方便用的，取得常數
    private var pdatas: [OneSub1Info] { BibleVersionConstants.s.datas }
    
    private func initCollectionViews(){
        viewCollectionItems.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "item")
        viewCollectionItems.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsVisibleNow.count
    }


    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath)
        
        if cell.contentView.subviews.count == 0 {
            let re = ButtonVersion()
            cell.contentView.addSubview(re)
            re.add4ConstrainsWithSuperView()
            re.addAction(UIAction(handler: onClickVersionItem), for: .primaryActionTriggered)
        }
        
        let btn = cell.contentView.subviews.first! as! ButtonVersion
        drawVersionItems(btn, indexPath.row)
        
        return cell
    }

    /// info 具有, 此 version 的 na,
    /// 也具有此 version 所需的條件 cds, (同時成立才能顯示, 用於 中文)
    /// tp 就是 TpSub2 array 型態
    class ButtonVersion : InfoButtonBase<OneVersionInfo> {
        override func initedBtn() {
            super.initedBtn()
            borderWidth = 1.0
        }
    }
    /// info 具有, 此 tp 例如, .ch 還是 .en ... TpSub1ChEnHGMiHaOt
    /// info 具有 vers, 所以可以作為初始化
    class ButtonSub1: InfoButtonBase<OneSub1Info>{
        override func initedBtn() {
            super.initedBtn()
            self.borderWidth = 1.0
        }
    }
    /// info 具有 sub2 type.
    class ButtonSub2: InfoButtonBase<TpSub2>{
        /// 不是用程式建立的 button, 怎麼傳 tp 作為 info 呢
        /// 只好用 tag 這個值來作為 info 初始用
        /// 首先，把所有的 IB 中的 custom class 設為 ButtonSub2
        /// 再來，從 IB 中設定它們的 tag 即可
        /// 注意!!! custom class 要設 ViewVersionsPicker.ButtonSub2 而不是直接設 ButtonSub2
        /// 注意!!! 上一行說的方法不行, 用 typealias 也不行, 就是要再宣告個外部的 class 啦 ....
        fileprivate func initInfoUsingTag() {
            let r1: [Int:TpSub2] = [
                1:.pr, 2:.cc, 3:.ro,
                11:.officer, 12:.ccht, 13:.study,
                21:.yr1800, 22:.yr1850, 23:.yr1919, 24:.yr1960, 25:.yrnow
            ]
            let r2 = r1[tag]
            if r2 != nil {
                info = r2!
            }
        }
        
        override func initedBtn() {
            super.initedBtn()
            self.borderWidth = 1.0
            
            initInfoUsingTag()
        }
    }
    class ButtonSet : InfoButtonBase<[OneVersionInfo]> {
        override func initedBtn() {
            super.initedBtn()
            borderWidth = 1.0
        }
        /// 使用每個版本的第1個字，串起來
        var title: String {
            if info == nil || info!.count == 0 {
                return "empty"
            }
            let r1 = info!.map({$0.cna.first!})
            return String(r1)
        }
    }
    typealias OneSub1Info = BibleVersionConstants.OneGroup
    typealias OneVersionInfo = BibleVersionConstants.One
    typealias TpSub1ChEnHGMiHaOt = BibleVersionConstants.TpGroup
    typealias TpSub2 = BibleVersionConstants.TpChtSub
}
/// 為了在 IB 中使用
class ViewVersionsPickerButtonSub2: ViewVersionsPicker.ButtonSub2 {}
