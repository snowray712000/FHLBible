//
//  ViewButtons.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/1.
//

import Foundation

import UIKit

class ViewButtons : ViewFromXibBase, UICollectionViewDataSource {
    override var nibName: String { "ViewButtons"}
    @IBOutlet weak var viewCollection: UICollectionView!
    func setButtons(_ titles: [String],_ idxCurrent: Int){
        self._datas = titles.map({($0,nil)})
        self._idxCur = idxCurrent
    }
    /// idxCurrent 是 idx, 不是 idInfo
    /// 因為對 ViewButtons 來說，我管理的是 idx。
    /// 若 idx 超出範圍，也沒關係，它只會使範圍內的 title color 變為紅色
    func setButtons(_ titles: [String],_ infos: [Int?],_ idxCurrent:Int){
        _datas = ijnRange(0, titles.count).map({(titles[$0],infos[$0])})
        self._idxCur = idxCurrent
    }
    var onClick$: IjnEvent<InfoButton, Int> = IjnEvent()

    private var _onClick$: IjnEvent<InfoButton, Int> = IjnEvent()
    private var _datas: [(String,Int?)] = [] {
        didSet {
            self.calcMaxButtonSize()
            self.updateConstraintsForPrettryLayout()
            viewCollection.reloadData()
        }
    }
    /// 有些方塊大，有的小，排起來會很醜
    private func calcMaxButtonSize(){
        let r1 = ijnRange(0, _datas.count).map({ i -> InfoButton in
            let r2 = gBtn(i)
            r2.setTitle(self._datas[i].0, for: .normal)
            return r2
        })
        let r3 = r1.max { a1, a2 in
            if a1.intrinsicContentSize.width > a2.intrinsicContentSize.width {
                return false
            }
            return true
        }
        self._szButtonPretty = r3!.intrinsicContentSize
    }
    private var _szButtonPretty: CGSize =  CGSize()
    private func updateConstraintsForPrettryLayout(){
        self._btns.forEach({ a1 in
            a1.removeContrainsRelativeMe()
            a1.add4ConstrainsWithSuperView()
            a1.widthAnchor.constraint(greaterThanOrEqualToConstant: self._szButtonPretty.width).isActive = true
        })
    }
    
    /// 當按下某個時，其它的要 title color 變為 blue 時會用到
    /// 重新計算出 _szButtonPretty 時，也會用到，要讓它們的 width constrol update
    private var _btns: [InfoButton] = []
    /// 當按下某個時，index要變，因為 reuse 的概念，所以 color 每次 reuse 時也要設 red 或 blue
    private var _idxCur: Int = -1
    override func initedFromXib() {
        let chaps = ijnRange(1, 150).map({"\($0)"})
        self.setButtons(chaps, 3)
        
        viewCollection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        viewCollection.dataSource = self
        
        _onClick$.addCallback { sender, pData in
            self._btns.forEach({$0.setTitleColor(.systemBlue, for: .normal)})
            sender?.setTitleColor(.systemRed, for: .normal)
            
            self._idxCur = pData!
            
            self.onClick$.trigger(sender, pData)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        
        if cell.contentView.subviews.count == 0 {
            let r1 = gBtn(indexPath.row)
            cell.contentView.addSubview(r1)
            
            r1.add4ConstrainsWithSuperView()
            r1.widthAnchor.constraint(greaterThanOrEqualToConstant: self._szButtonPretty.width).isActive = true
            
            r1.addAction(UIAction(handler: { a1 in
                let r2 = a1.sender as! InfoButton
                self._onClick$.trigger(r2, r2.idReuse)
            }), for: .primaryActionTriggered)
            
            _btns.append(r1)
        }
        
        let btn = cell.contentView.subviews.first! as! InfoButton
        btn.idReuse = indexPath.row
        btn.idInfo = _datas[indexPath.row].1
        btn.setTitle(_datas[indexPath.row].0, for: .normal)
        if self._idxCur != -1 && _idxCur == btn.idReuse {
            btn.setTitleColor(.systemRed, for: .normal)
        } else {
            btn.setTitleColor(.systemBlue, for: .normal)
        }
        
        
        return cell
    }
    private func gBtn(_ idx: Int)->InfoButton {
        let r1 = InfoButton()
        // r1.backgroundColor = .lightGray debug 
        r1.contentEdgeInsets.top = 3
        r1.contentEdgeInsets.bottom = 3
        r1.contentEdgeInsets.left = 3
        r1.contentEdgeInsets.right = 3
        return r1
    }

    class InfoButton : UIButton {
        var idReuse: Int = -1
        /// 像 新約, 或是, 希伯來順序, 它們的 idx 就不一定等於 id
        /// 新約 太 idReuse = 0, 但 id = 40
        var idInfo: Int? = nil
    }
    
}
